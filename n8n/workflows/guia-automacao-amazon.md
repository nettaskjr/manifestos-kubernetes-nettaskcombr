# Guia: Configuração do Workflow n8n para Amazon Associates

Este guia descreve os nós necessários para montar a automação de vendas no n8n.

## Estrutura do Workflow

### 1. Gatilho Agendado (Schedule Trigger)
*   **Intervalo**: Diário (ex: 08:00 AM).
*   **Objetivo**: Iniciar o processo de busca de tendências todas as manhãs.

### 2. Scraping de Tendências (HTTP Request)
*   **URL**: `https://www.amazon.com.br/gp/bestsellers/beauty` (ou similar).
*   **Método**: GET.
*   **Pós-processamento (HTML Extract)**: Extrair nome do produto, link e imagem principal.

### 3. Filtro de Relevância (Filter Node)
*   **Condição**: Apenas produtos que não foram postados nos últimos 30 dias (usar banco de dados Postgres para verificar).

### 4. Geração de Roteiro (Google Generative AI Node)
*   **Modelo**: Gemini 1.5 Flash ou Pro.
*   **Prompt**: "Crie um roteiro curto e viral de 15 segundos para o produto {product_name}. Foco em benefícios e curiosidade. Idioma: Português."

### 5. Chamada ao Video Processor (HTTP Request)
*   **URL**: `http://video-processor.n8n.svc.cluster.local:5000/process`
*   **Método**: POST.
*   **Body (JSON)**:
    ```json
    {
      "id": "{{ $node["Extract"].json["id"] }}",
      "name": "{{ $node["Extract"].json["name"] }}",
      "images": ["{{ $node["Extract"].json["image_url"] }}"],
      "description": "{{ $node["OpenAI"].json["script"] }}"
    }
    ```
*   **Resultado**: O nó receberá a `video_url` do MinIO.

### 6. Postagem TikTok (TikTok Node / HTTP Request)
*   **Ação**: Postar vídeo.
*   **Dados**: Usar a `video_url` e o roteiro como legenda.
*   **Link**: Adicionar o link de afiliado na legenda ou direcionar para a bio.

### 7. Registro no Banco de Dados (Postgres Node)
*   **Objetivo**: Marcar o produto como "postado" para evitar duplicidade.

## Variáveis de Ambiente Necessárias
As seguintes credenciais devem ser configuradas no n8n:
*   **Amazon API** (opcional, se usar scraping puro não precisa).
*   **Google Gemini API Key**.
*   **TikTok Developer API Credentials**.
*   **MinIO Credentials** (para ler o vídeo final se necessário, embora o processador já faça o upload).
