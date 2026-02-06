#!/bin/bash
# scripts/setup-app.sh - Automação especializada para o Repositório do Cliente

CONTEXT_FILE="/etc/infra/context.env"
[ -f "$CONTEXT_FILE" ] && source "$CONTEXT_FILE"

echo "🎯 Iniciando setup especializado da aplicação..."

# 1. Gestão de Segredos Persistentes (Local no Servidor)
SECRETS_DIR="/mnt/db-vol/k8s-secrets"
mkdir -p "$SECRETS_DIR"

get_or_gen_secret() {
  local NAME=$1
  local FILE="$SECRETS_DIR/$NAME"
  if [ ! -f "$FILE" ]; then
    openssl rand -hex 16 > "$FILE"
    chmod 600 "$FILE"
  fi
  cat "$FILE"
}

N8N_DB_PASS=$(get_or_gen_secret "n8n_db_password")
N8N_ENC_KEY=$(get_or_gen_secret "n8n_encryption_key")

# 2. Criar Segretos no Kubernetes (Namespace n8n)
echo "🔑 Configurando segredos no Kubernetes..."
kubectl create secret generic n8n-secrets -n n8n \
    --from-literal=n8n-db-password="$N8N_DB_PASS" \
    --from-literal=n8n-encryption-key="$N8N_ENC_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

# 3. Provisionamento do Banco de Dados
echo "🐘 Verificando Banco de Dados PostgreSQL..."
PG_POD=$(kubectl get pods -n database -l app=postgres -o name | head -n 1)

if [ -n "$PG_POD" ]; then
  # Criar Banco
  kubectl exec -n database "$PG_POD" -- psql -U admin -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'n8n'" | grep -q 1 || \
    kubectl exec -n database "$PG_POD" -- psql -U admin -d postgres -c "CREATE DATABASE n8n;"
  
  # Criar Usuário
  kubectl exec -n database "$PG_POD" -- psql -U admin -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = 'n8n_user'" | grep -q 1 || \
    kubectl exec -n database "$PG_POD" -- psql -U admin -d postgres -c "CREATE USER n8n_user WITH PASSWORD '$N8N_DB_PASS';"
  
  # Permissões
  kubectl exec -n database "$PG_POD" -- psql -U admin -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;"
  echo "✅ Banco de Dados n8n pronto!"
else
  echo "⚠️ Erro: Pod do Postgres não encontrado. O banco n8n deve ser criado manualmente ou após o deploy da infra."
fi
