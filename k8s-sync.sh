#!/bin/bash
# k8s-sync.sh - Sincroniza manifestos Kubernetes preservando o Git limpo
# Este script deve rodar dentro do servidor OCI.

CONTEXT_FILE="/etc/infra/context.env"

# 1. Carregar contexto se existir
if [ -f "$CONTEXT_FILE" ]; then
    source "$CONTEXT_FILE"
else
    echo "⚠️ Contexto de infra não encontrado em $CONTEXT_FILE."
    echo "Por favor, defina as variáveis INFRA_DOMAIN manualmente se necessário."
fi

# Variáveis padrão (caso o contexto falhe)
DOMAIN="${INFRA_DOMAIN:-yourdomain.com}"
USER_HOME="${INFRA_USER_HOME:-/home/ubuntu}"
NODE_NAME="${INFRA_NODE_NAME:-k8s-node}"
INTERNAL_DNS="${INFRA_INTERNAL_DNS:-k8s-node.public.mainvcn.oraclevcn.com}"

# O diretório alvo é sempre aquele onde o script está
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Iniciando sincronização do Kubernetes..."
echo "📂 Pasta alvo: $TARGET_DIR"

# 2. Criar diretório temporário
WORKING_DIR=$(mktemp -d)
echo "📦 Criando ambiente temporário em $WORKING_DIR..."
cp -r "$TARGET_DIR"/* "$WORKING_DIR/"

# 3. Aplicar Substituições (SED) na pasta temporária
echo "🔧 Aplicando configurações locais (Placeholders)..."
find "$WORKING_DIR" -name "*.yaml" -type f -exec sed -i "s|<<seu-dominio>>|$DOMAIN|g" {} +
find "$WORKING_DIR" -name "*.yaml" -type f -exec sed -i "s|<<user-home>>|$USER_HOME|g" {} +
find "$WORKING_DIR" -name "*.yaml" -type f -exec sed -i "s|<<k8s-node-name>>|$NODE_NAME|g" {} +
find "$WORKING_DIR" -name "*.yaml" -type f -exec sed -i "s|<<k8s-internal-dns>>|$INTERNAL_DNS|g" {} +

# 4. Aplicar no Kubernetes
echo "☸️ Aplicando manifestos no cluster (YAML)..."
find "$WORKING_DIR" -type f ! \( -name "*.yaml" -o -name "*.yml" \) -delete
sudo k3s kubectl apply -R -f "$WORKING_DIR"

# 5. Executar Scripts de Setup Especializados (se existirem)
if [ -f "$TARGET_DIR/scripts/setup-app.sh" ]; then
    echo "🎯 Executando setup especializado do repositório..."
    bash "$TARGET_DIR/scripts/setup-app.sh"
fi

# 6. Limpeza
echo "🧹 Limpando arquivos temporários..."
rm -rf "$WORKING_DIR"

echo "✅ Sincronização concluída com sucesso!"
echo "💡 Dica: Seus arquivos em $TARGET_DIR continuam limpos para o próximo 'git pull'."
