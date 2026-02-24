#!/bin/bash
# scripts/setup-app.sh - Automação especializada para o Repositório do Cliente

CONTEXT_FILE="/etc/infra/context.env"
[ -f "$CONTEXT_FILE" ] && source "$CONTEXT_FILE"

echo "🎯 Iniciando setup especializado das aplicações..."

# 0. Preparação do Namespace
kubectl create namespace n8n --dry-run=client -o yaml | kubectl apply -f -

# 1. Gestão de Segredos Persistentes (Local no Servidor)
SECRETS_DIR="/mnt/db-vol/k8s-secrets"
# Garantir que o diretório existe e é acessível
sudo mkdir -p "$SECRETS_DIR"
sudo chown -R ubuntu:ubuntu "$SECRETS_DIR"

get_or_gen_secret() {
  local NAME=$1
  local FILE="$SECRETS_DIR/$NAME"
  if [ ! -f "$FILE" ]; then
    echo "Gerando segredo $NAME..."
    openssl rand -hex 16 > "$FILE"
    chmod 600 "$FILE"
  fi
  cat "$FILE"
}

N8N_DB_PASS=$(get_or_gen_secret "n8n_db_password")
N8N_ENC_KEY=$(get_or_gen_secret "n8n_encryption_key")

if [ -z "$N8N_DB_PASS" ] || [ -z "$N8N_ENC_KEY" ]; then
  echo "❌ Erro crítico: Não foi possível gerar ou ler os segredos em $SECRETS_DIR"
  exit 1
fi

# 2. Configuração de ConfigMaps Base (Namespace n8n)
echo "⚙️ Configurando ConfigMaps de aplicação..."
# Garantir que o ConfigMap existe com os valores universais e específicos
# Usamos INFRA_DOMAIN (carregado do context.env) em vez de domain_name
kubectl create configmap infra-config -n n8n --dry-run=client -o yaml | kubectl apply -f -
kubectl patch configmap infra-config -n n8n --type merge -p "{\"data\":{\"domain\":\"$INFRA_DOMAIN\", \"node-name\":\"$INFRA_NODE_NAME\", \"internal-dns\":\"$INFRA_INTERNAL_DNS\", \"n8n-db-name\":\"n8n\", \"n8n-db-user\":\"n8n_user\"}}"

# 3. Coletar Segredos de Outros Namespaces (MinIO)
echo "📦 Coletando credenciais do MinIO..."
MINIO_PASS=$(kubectl get secret infra-secrets -n minio -o jsonpath='{.data.minio-root-password}' | base64 -d)

# 4. Criar Segretos no Kubernetes (Namespace n8n)
echo "🔑 Configurando segredos no Kubernetes (n8n)..."
kubectl create secret generic n8n-secrets -n n8n \
    --from-literal=n8n-db-password="$N8N_DB_PASS" \
    --from-literal=n8n-encryption-key="$N8N_ENC_KEY" \
    --from-literal=minio-access-key="admin" \
    --from-literal=minio-secret-key="$MINIO_PASS" \
    --dry-run=client -o yaml | kubectl apply -f -

# 5. Reiniciar n8n para aplicar mudanças
echo "🔄 Reiniciando n8n (para garantir leitura de novos segredos)..."
kubectl rollout restart deployment n8n -n n8n || true
echo "🚀 Setup das aplicações concluído! Verifique os logs em alguns instantes."
