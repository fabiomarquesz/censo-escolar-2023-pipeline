
# Camda silver - Limpeza, tipagem e recodificação
source("R/utils.R")

library(dplyr)
library(tidyr)

# Leitura da camada Bronze
log_msg("Conectando ao Bronze...")
con_bronze <- mongo_connect("bronze_escolas")

log_msg(paste("Total de documentos no Bronze:", con_bronze$count()))
log_msg("Carregando dados do Bronze")

df_bronze <- con_bronze$find()

log_msg(paste("Dados carregados:", nrow(df_bronze), "linhas"))

# Seleção das colunas relevantes
log_msg("Selecionando colunas relevantes...")

df_silver <- df_bronze |>
  select(
    #Identificação
    CO_ENTIDADE, NO_ENTIDADE,
    
    #Localização
    SG_UF, NO_UF, CO_MUNICIPIO, NO_MUNICIPIO, NO_REGIAO, TP_LOCALIZACAO,TP_LOCALIZACAO_DIFERENCIADA,
    
    #Dependência administrativa
    TP_DEPENDENCIA,
    
    #Situação de funcionamento
    TP_SITUACAO_FUNCIONAMENTO,
    
    #Infraestrutura
    IN_BIBLIOTECA, IN_LABORATORIO_INFORMATICA, IN_LABORATORIO_CIENCIAS,
    IN_QUADRA_ESPORTES, IN_INTERNET, IN_INTERNET_ALUNOS,
    IN_BANDA_LARGA, IN_ENERGIA_REDE_PUBLICA,
    
    #Etapas do ensino ofertadas
    IN_INF_CRE, IN_INF_PRE, # Educação Infantil
    IN_FUND_AI, IN_FUND_AF, # Ensino Fudamental
    IN_MED, # Ensino Médio
    IN_EJA, IN_PROF # EJA e Profissional
  )

log_msg(paste("Colunas selecionadas:", ncol(df_silver)))

# Tipagem correta
log_msg("Aplicando tipagem...")

df_silver <- df_silver |>
  mutate(
    # Identificadores numéricos
    CO_ENTIDADE  = as.integer(CO_ENTIDADE),
    CO_MUNICIPIO = as.integer(CO_MUNICIPIO),
    
    # Localização
    TP_LOCALIZACAO = case_when(
      TP_LOCALIZACAO == "1" ~ "Urbana",
      TP_LOCALIZACAO == "2" ~ "Rural",
      TRUE ~ NA_character_
    ),
    
    TP_LOCALIZACAO_DIFERENCIADA = case_when(
      TP_LOCALIZACAO_DIFERENCIADA == "1" ~ "Área de assentamento",
      TP_LOCALIZACAO_DIFERENCIADA == "2" ~ "Terra indígena",
      TP_LOCALIZACAO_DIFERENCIADA == "3" ~ "Área remanescente quilombos",
      TP_LOCALIZACAO_DIFERENCIADA == "7" ~ "Não se aplica",
      TRUE ~ NA_character_
    ),
    
    # Dependência administrativa
    TP_DEPENDENCIA = case_when(
      TP_DEPENDENCIA == "1" ~ "Federal",
      TP_DEPENDENCIA == "2" ~ "Estadual",
      TP_DEPENDENCIA == "3" ~ "Municipal",
      TP_DEPENDENCIA == "4" ~ "Privada",
      TRUE ~ NA_character_
    ),
    
    # Situação de funcionamento
    TP_SITUACAO_FUNCIONAMENTO = case_when(
      TP_SITUACAO_FUNCIONAMENTO == "1" ~ "Em atividade",
      TP_SITUACAO_FUNCIONAMENTO == "2" ~ "Paralisada",
      TP_SITUACAO_FUNCIONAMENTO == "3" ~ "Extinta",
      TP_SITUACAO_FUNCIONAMENTO == "4" ~ "Extinta (ano anterior)",
      TRUE ~ NA_character_
    )
  ) |>
  # Variáveis binárias IN_ em mutate separado para evitar conflito de tipos
  mutate(
    across(
      starts_with("IN_"),
      ~ as.integer(.x)
    )
  )

# Filtro - Apenas escolas em atividade
log_msg("Filtrando apenas escolas em atividade...")

df_silver <- df_silver |>
  filter(TP_SITUACAO_FUNCIONAMENTO == "Em atividade")

log_msg(paste("Escolas em atividade:", nrow(df_silver)))

# Validação rápida

log_msg("Amostra da camada Silver:")
glimpse(df_silver)

cat("\nDistribuição por dependência:\n")
print(table(df_silver$TP_DEPENDENCIA))

cat("\nDistribuição por localização:\n")
print(table(df_silver$TP_LOCALIZACAO))

# Ingestão no MongoDB - Coleção silver_escolas

log_msg("Conectando ao Silver...")
con_silver <- mongo_connect("silver_escolas")
con_silver$remove("{}")
con_silver <- mongo_connect("silver_escolas")

log_msg("Inserindo dados na camada Silver...")
con_silver$insert(df_silver)

total_silver <- con_silver$count()
log_msg(paste("Silver concluído! Total de documentos:", total_silver))