#!/bin/sh

set -e

echo "A aguardar o arranque do auth-service..."
until curl -s http://auth-service:8001/health > /dev/null; do
  sleep 2
done
echo "auth-service está online"

echo "A gerar a chave de API de servico..."
RESPONSE=$(curl -s -X POST http://auth-service:8001/admin/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${MASTER_KEY}" \
  -d '{"name": "evaluation-service-auto-key"}')

export SERVICE_API_KEY=$(echo $RESPONSE | jq -r '.key')

if [ "$SERVICE_API_KEY" = "null" ] || [ -z "$SERVICE_API_KEY" ]; then
  echo "Erro ao gerar a chave de servico: $RESPONSE"
  exit 1
fi

echo "Chave de servico gerada e injectada com sucesso"

exec "$@"