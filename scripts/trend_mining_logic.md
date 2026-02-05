# Lógica: Daily Trend Mining (n8n)

Este documento descreve como o primeiro nó da nossa automação deve funcionar.

## Fontes de Entrada (Scraping)

### 1. TikTok Creative Center (Top Ads)
*   **Ação**: Usar um nó de HTTP Request para consultar a API (ou via scraping com Selenium/Playwright se necessário) buscando os top ads das categorias "Beauty" e "Health".
*   **Filtro**: CTR (Click-Through Rate) acima da média da indústria e mais de 100k impressões nos últimos 7 dias.

### 2. Amazon Best Sellers
*   **Ação**: Monitorar as páginas de [Best Sellers em Beleza](https://www.amazon.com.br/gp/bestsellers/beauty) e [Saúde](https://www.amazon.com.br/gp/bestsellers/hpc).
*   **Filtro**: Produtos que subiram pelo menos 5 posições no ranking nas últimas 24h (Movers & Shakers).

## Processamento de Dados (Node.js/Code Node)

O n8n deve processar a lista e gerar um objeto JSON para o próximo passo:
```json
{
  "product_name": "Sérum Facial Viral 123",
  "category": "Beleza",
  "trend_score": 95,
  "amazon_url": "https://amazon.com.br/...",
  "viral_hook_reference": "A transcrição do vídeo que viralizou no TikTok"
}
```

## Próximo Nó: AI Content Generation
O n8n enviará esses dados para o GPT-4 para criar o roteiro.
