package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
)

// initTracer configura o TracerProvider global do OpenTelemetry e devolve
// uma funcao de shutdown que deve ser chamada no termino do processo.
//
// Variaveis de ambiente consumidas (padronizadas pelo OpenTelemetry):
//
//	OTEL_SERVICE_NAME                nome do servico (ex: "evaluation-service")
//	OTEL_EXPORTER_OTLP_ENDPOINT      URL do collector (ex: http://.../v1/traces)
//	OTEL_EXPORTER_OTLP_PROTOCOL      "http/protobuf" (default assumido)
//	OTEL_RESOURCE_ATTRIBUTES         "k=v,..." adicionado ao Resource
//
// Se OTEL_EXPORTER_OTLP_ENDPOINT estiver vazio, o tracer vira no-op para
// nao impedir o processo de subir em desenvolvimento local sem collector.
func initTracer(ctx context.Context, serviceName string) (func(context.Context) error, error) {
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		log.Println("OTEL_EXPORTER_OTLP_ENDPOINT nao definido; tracing desativado.")
		return func(context.Context) error { return nil }, nil
	}

	// otlptracehttp.NewClient le as mesmas envs OTEL_EXPORTER_* padrao,
	// entao nao duplicamos a configuracao aqui.
	exporter, err := otlptrace.New(ctx, otlptracehttp.NewClient())
	if err != nil {
		return nil, fmt.Errorf("otel: criar exporter otlp: %w", err)
	}

	// Resource identifica o servico. Valores explicitos tem prioridade
	// sobre o que vier do env OTEL_RESOURCE_ATTRIBUTES.
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

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter,
			sdktrace.WithBatchTimeout(5*time.Second),
		),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
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
		return tp.Shutdown(shutdownCtx)
	}, nil
}
