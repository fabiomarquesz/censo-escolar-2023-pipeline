# Censo Escolar 2023 — Pipeline de Dados

Pipeline de engenharia de dados com R e MongoDB seguindo a arquitetura Medallion (Bronze → Silver → Gold).

## 📊 Relatório

👉 [Acesse o relatório completo aqui](https://fabiomarquesz.github.io/censo-escolar-2023-pipeline/)

## Stack

- R 4.6 + RStudio
- MongoDB 7 (Community)
- mongolite · dplyr · ggplot2 · Quarto

## Arquitetura

| Camada | Coleção MongoDB      | Registros |
|--------|----------------------|-----------|
| Bronze | `bronze_escolas`     | 217.625   |
| Silver | `silver_escolas`     | 180.230   |
| Gold   | 5 coleções agregadas | —         |

## Como executar

```r
source("R/01_bronze_ingest.R")
source("R/02_silver_clean.R")
source("R/03_gold_aggregate.R")
quarto::quarto_render("quarto/relatorio_final.qmd")
```

## Fonte dos dados

INEP — [Censo Escolar 2023](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar)