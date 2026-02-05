# Guia de Configuração de Secrets (Segurança)

Para evitar que senhas fiquem expostas no repositório, utilizaremos o objeto `Secret` do Kubernetes.

## Opção 1: Via Linha de Comando (Recomendado)

Execute os comandos abaixo diretamente no seu terminal (ajustando os valores):

```bash
# 1. Criar o segredo com a senha do banco e a chave de criptografia do n8n
sudo k3s kubectl create secret generic n8n-secrets \
  --namespace n8n-sales \
  --from-literal=database-password='SUA_SENHA_DO_POSTGRES' \
  --from-literal=encryption-key='UMA_CHAVE_ALEATORIA_LONGA'
```

## Opção 2: Via Arquivo (Não versionar este arquivo!)

Se preferir usar um arquivo YAML (garantindo que ele esteja no seu `.gitignore`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: n8n-secrets
  namespace: n8n-sales
type: Opaque
stringData:
  database-password: SUA_SENHA_DO_POSTGRES
  encryption-key: UMA_CHAVE_ALEATORIA_LONGA
```

> [!WARNING]
> Nunca faça commit do arquivo de Secrets com valores reais. Use sempre a Opção 1 se possível.
