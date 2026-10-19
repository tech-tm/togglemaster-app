# Instrumentação OpenTelemetry (Fase 4 — Bloco 3)

Este documento descreve como os 5 microsserviços do ToggleMaster foram instrumentados
com **OpenTelemetry** para gerar traces, métricas e logs correlacionados que são
enviados ao **OTel Collector** (Bloco 2), que por sua vez roteia para Datadog (APM)
e Prometheus (métricas) — conforme exigido pela Fase 4.

## Visão geral

```text
┌──────────────────────────────────────────────────────────────┐
│  Microsserviços (togglemaster-app/src)                       │
│                                                              │
│  Python (3): flag-service, targeting-service, analytics      │
│    → opentelemetry-instrument (CLI, auto-instrumentação)     │
│                                                              │
│  Go (2): auth-service, evaluation-service                    │
│    → go.opentelemetry.io/otel (SDK, instrumentação manual)   │
└───────────────────────┬──────────────────────────────────────┘
                        │ OTLP HTTP (protobuf) :4318
                        ▼
          otel-collector-opentelemetry-collector
                 (namespace observability)
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
       Datadog                   Prometheus
   (APM / traces /            (métricas via
    logs / metrics)             scrape :8889)
```

## Estratégia por linguagem

### Python (3 serviços)

**Zero mudanças em `app.py`.** Toda a instrumentação é zero-touch via CLI.

**Mudanças por serviço:**

| Arquivo | Mudança |
|---|---|
| `requirements.txt` | +6 pacotes OTel |
| `Dockerfile` | CMD prefixado com `opentelemetry-instrument` |

**Pacotes OTel adicionados** (`flag-service`, `targeting-service`):

```
opentelemetry-distro==0.52b0
opentelemetry-exporter-otlp-proto-http==1.31.0
opentelemetry-instrumentation-flask==0.52b0
opentelemetry-instrumentation-requests==0.52b0
opentelemetry-instrumentation-psycopg2==0.52b0
opentelemetry-instrumentation-logging==0.52b0
```

**Diferença no `analytics-service`:** troca `-psycopg2` por `-botocore` (SQS +
DynamoDB em vez de Postgres).

**O que a auto-instrumentação captura:**

| Instrumentação | Spans gerados |
|---|---|
| Flask | Cada requisição HTTP recebida (rota, método, status, latência) |
| requests | Chamadas HTTP outbound (ex: `flag-service` → `auth-service`) com propagação de `traceparent` |
| psycopg2 | Queries SQL executadas (`SELECT`, `INSERT`, `UPDATE`, etc.) |
| botocore | Chamadas AWS (SQS `ReceiveMessage`/`DeleteMessage`, DynamoDB `PutItem`) |
| logging | Correlação automática de `trace_id` e `span_id` nos registros de log |

### Go (2 serviços)

**Instrumentação manual com SDK.** Não existe modo zero-touch estável para Go
que não exija privilégios especiais (eBPF).

**Mudanças comuns (`auth-service` e `evaluation-service`):**

| Arquivo | Mudança |
|---|---|
| `otel.go` | **novo** — função `initTracer()` que configura TracerProvider, exporter OTLP HTTP e propagadores W3C |
| `main.go` | Chama `initTracer` no boot + envolve o `mux` com `otelhttp.NewHandler(mux, "<nome-servico>")` |
| `go.mod` | +5 deps diretas OTel |

**Mudanças adicionais apenas no `evaluation-service`:**

| Arquivo | Mudança |
|---|---|
| `main.go` | `*http.Client` configurado com `Transport: otelhttp.NewTransport(http.DefaultTransport)` |
| `handlers.go` | `evaluationHandler` passa `r.Context()` para `getDecision` |
| `evaluator.go` | `getDecision`, `getCombinedFlagInfo`, `fetchFromServices`, `fetchFlag`, `fetchRule` recebem `context.Context` como primeiro parâmetro, e as duas funções `fetch*` usam `http.NewRequestWithContext` |

Essa propagação de contexto é **essencial para o Service Map**: sem ela, os spans
client-side do `evaluation-service` não ficam ligados aos server-side do
`flag-service`/`targeting-service`, e o Datadog mostra os serviços como ilhas.

## Variáveis de ambiente (padronizadas OpenTelemetry)

Injetadas pelos Deployments no cluster (`togglemaster-deploy/k8s/base/services/*/deployment.yaml`):

| Variável | Valor | Origem | Observação |
|---|---|---|---|
| `OTEL_SERVICE_NAME` | `<nome do serviço>` | Deployment (literal) | Diferente por serviço |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4318` | ConfigMap `togglemaster-config` | Endpoint do Collector (Bloco 2) |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | ConfigMap `togglemaster-config` | — |
| `OTEL_RESOURCE_ATTRIBUTES` | `deployment.environment=prod` | ConfigMap `togglemaster-config` | — |
| `OTEL_LOGS_EXPORTER` | `otlp` | Deployment (literal) | **Apenas nos 3 Python** |
| `OTEL_PYTHON_LOG_CORRELATION` | `true` | Deployment (literal) | **Apenas nos 3 Python** |

A chave `OTEL_EXPORTER_OTLP_ENDPOINT` é adicionada ao ConfigMap `togglemaster-config`
pelo workflow `togglemaster-deploy/.github/workflows/gitops.yml`.

## Comportamento em desenvolvimento local

Sem `OTEL_EXPORTER_OTLP_ENDPOINT` definido:

- **Go**: `initTracer` detecta a env vazia e vira **no-op silencioso** — o processo sobe normalmente, nenhum span é exportado.
- **Python**: `opentelemetry-instrument` carrega as instrumentações mas o exporter OTLP falha silenciosamente ao conectar — processo continua funcionando.

Isso significa que os microsserviços continuam **100% funcionais** em `docker-compose up` local sem exigir Collector.

## Validação realizada

Antes do deploy em cluster, as mudanças foram validadas localmente:

| Serviço | Validação |
|---|---|
| flag-service | `pip install -r requirements.txt` em `python:3.12-slim` → OK |
| targeting-service | idem → OK |
| analytics-service | idem → OK |
| auth-service | `go mod tidy && go build` em `golang:1.25-alpine` → OK |
| evaluation-service | `go mod tidy && go vet ./... && go build` em `golang:1.25-alpine` → OK |

A validação end-to-end (traces fluindo até o Datadog, Service Map populado)
requer cluster EKS ativo com o Bloco 2 (Collector) rodando e o secret
`datadog-secret` sincronizado.
