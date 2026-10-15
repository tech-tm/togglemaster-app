FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir setuptools
COPY . .
EXPOSE 8002
# OpenTelemetry (Fase 4 - Bloco 3):
# A CLI 'opentelemetry-instrument' aplica auto-instrumentacao sobre
# o processo filho (gunicorn + app Flask). As libs de instrumentacao
# declaradas em requirements.txt sao detectadas e carregadas em runtime.
# Configuracao via envs OTEL_* no manifesto Kubernetes.
CMD ["opentelemetry-instrument", "gunicorn", "--bind", "0.0.0.0:8002", "app:app"]
