
#Camada bronze - Leitura do CSV e ingestão bruta no MongoDB
source("R/utils.R")

library(readr)
library(dplyr)

# Configuração de caminhos
caminho_csv <- "data/raw/microdados_censo_escolar_2023/dados/microdados_ed_basica_2023.csv"

# Leitura do CSV
log_msg("Iniciando leitura do CSV...")

df_bronze <- read_delim(
  file = caminho_csv,
  delim = ";",
  locale = locale(encoding = "latin1"),
  col_types = cols(.default = "c"), # Converter tudo para character no Bronze
  progress = TRUE
)

log_msg(paste("Leitura concluída:", nrow(df_bronze), "linhas |", ncol(df_bronze), "colunas"))

# Verificação rápida antes de inserir
glimpse(df_bronze[, 1:10])

# Ingestão no MongoDB - coleção bronze_escola
log_msg("Conectando ao MongoDB...")
con_bronze <- mongo_connect("bronze_escolas")

# Limpando a coleção caso já exista (idempotência)
con_bronze$remove("{}")
con_bronze <- mongo_connect("bronze_escolas")
log_msg("Coleção pronta para ingestão.")


# Inserção em lotes de 10.000 linhas para evitar timeout
log_msg("Iniciando inserção no MongoDB...")

batch_size <- 1000
total <- nrow(df_bronze)
batches <- ceiling(total / batch_size)

for( i in seq_len(batches)){
  inicio <- (i - 1) * batch_size + 1
  fim <- min(i * batch_size, total)
  con_bronze$insert(df_bronze[inicio:fim,])
  log_msg(paste0(" Lote ", i, "/", batches, " inserindo (linhas", inicio, " a ", fim, ")"))
}

# Validação final
total_inserido <- con_bronze$count()
log_msg(paste("Ingestão concluída! Total de documentos no MongoDB:", total_inserido))

# Amostra de 3 documentos para conferência visual
amostra <- con_bronze$find(limit = 3)
print(amostra[, 1:8])