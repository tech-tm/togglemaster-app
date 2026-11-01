package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

// initOTel configura TracerProvider E MeterProvider globais do OpenTelemetry
// e devolve uma funcao de shutdown que deve ser chamada no termino do
// processo.
//
// Variaveis de ambiente consumidas (padronizadas pelo OpenTelemetry):
//
//	OTEL_SERVICE_NAME                nome do servico (ex: "auth-service")
//	OTEL_EXPORTER_OTLP_ENDPOINT      URL do collector (ex: http://.../)
//	OTEL_EXPORTER_OTLP_PROTOCOL      "http/protobuf" (default assumido)
//	OTEL_RESOURCE_ATTRIBUTES         "k=v,..." adicionado ao Resource
//
// Se OTEL_EXPORTER_OTLP_ENDPOINT estiver vazio, ambos os providers viram
// no-op para nao impedir o processo de subir em desenvolvimento local
// sem collector.
//
// Por que configurar MeterProvider: o 'otelhttp.NewHandler' usa o
// MeterProvider global para emitir metricas HTTP server (histogram
// 'http.server.request.duration', contadores, etc.). Sem um provider
// explicito, o default e no-op e nenhuma metrica HTTP e emitida — por
// isso o painel 'Requisicoes HTTP por servico' do Grafana fica vazio
// para os servicos Go.
func initOTel(ctx context.Context, serviceName string) (func(context.Context) error, error) {
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		log.Println("OTEL_EXPORTER_OTLP_ENDPOINT nao definido; OTel desativado.")
		return func(context.Context) error { return nil }, nil
	}

	// Resource identifica o servico. Compartilhado entre traces e metricas.
	// Valores explicitos tem prioridade sobre o que vier do env
	// OTEL_RESOURCE_ATTRIBUTES.
	res, err := resource.New(ctx,
		resource.WithFromEnv(),
		resource.WithHost(),
		resource.WithTelemetrySDK(),
		resource.WithAttributes(
			semconv.ServiceName(serviceName),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("otel: criar resource: %w", err)
	}

	// --- TracerProvider ---------------------------------------------------
	// otlptracehttp.NewClient le as mesmas envs OTEL_EXPORTER_* padrao,
	// entao nao duplicamos a configuracao aqui.
	traceExporter, err := otlptrace.New(ctx, otlptracehttp.NewClient())
	if err != nil {
		return nil, fmt.Errorf("otel: criar trace exporter: %w", err)
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(traceExporter,
			sdktrace.WithBatchTimeout(5*time.Second),
		),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)

	// --- MeterProvider ----------------------------------------------------
	// otlpmetrichttp.New le as mesmas envs OTEL_EXPORTER_* padrao.
	// PeriodicReader empurra as metricas acumuladas a cada 10s.
	metricExporter, err := otlpmetrichttp.New(ctx)
	if err != nil {
		return nil, fmt.Errorf("otel: criar metric exporter: %w", err)
	}
	mp := metric.NewMeterProvider(
		metric.WithReader(metric.NewPeriodicReader(metricExporter,
			metric.WithInterval(10*time.Second),
		)),
		metric.WithResource(res),
	)
	otel.SetMeterProvider(mp)

	// Propagador W3C (traceparent + baggage) para que os IDs atravessem
	// chamadas HTTP entre os microsservicos.
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	log.Printf("OpenTelemetry inicializado (service=%s, endpoint=%s)", serviceName, endpoint)

	return func(ctx context.Context) error {
		shutdownCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		defer cancel()
		// Fecha os dois providers; retorna o primeiro erro encontrado
		// mas ainda tenta o outro shutdown.
		errTP := tp.Shutdown(shutdownCtx)
		errMP := mp.Shutdown(shutdownCtx)
		if errTP != nil {
			return errTP
		}
		return errMP
	}, nil
}
