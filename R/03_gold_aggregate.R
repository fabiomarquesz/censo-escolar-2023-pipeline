
#Camada Gold - Agregações e KPIs educacionais

source("R/utils.R")
library(dplyr)

# Leitura da camada silver
log_msg("Conetando ao Silver...")

con_silver <- mongo_connect("silver_escolas")
log_msg(paste("Total de documentos no Silver:", con_silver$count()))

log_msg("Carregando dados do Silver...")
df_silver <- con_silver$find()
log_msg(paste("Dados carregados:", nrow(df_silver), "linhas"))

# KPI 1 - Escolas por UF e dependência administrativa
log_msg("Calculando KPI 1: escolas por UF e dependência...")

gold_uf_dependencia <- df_silver |>
  group_by(NO_REGIAO, SG_UF, NO_UF, TP_DEPENDENCIA) |>
  summarise(total_escolas = n(), .groups = "drop") |>
  arrange(NO_REGIAO, SG_UF, TP_DEPENDENCIA)

# KPI 2 - Internet banda larga por UF
log_msg("Calculando KPI 2: Internet banda larga por UF...")

gold_internet_uf <- df_silver |>
  group_by(NO_REGIAO, SG_UF, NO_UF) |>
  summarise(
    total_escolas = n(),
    com_internet = sum(IN_INTERNET, na.rm = TRUE),
    com_banda_larga = sum(IN_BANDA_LARGA, na.rm = TRUE),
    pct_internet = round(com_internet / total_escolas * 100, 1),
    pct_banda_larga = round(com_banda_larga / total_escolas * 100, 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_banda_larga))

# KPI 3 - Oferta de etapas de ensino por rede

log_msg("Calculando KPI 3: Oferta de etapas por rede...")

gold_etapas_rede <- df_silver |>
  group_by(TP_DEPENDENCIA) |>
  summary(
    total_escolas = n(),
    infantil_cre = sum(IN_INF_CRE, na.rm = TRUE),
    infantil_pre = sum(IN_INF_PRE, na.rm = TRUE),
    fund_anos_ini = sum(IN_FUND_AI, na.rm = TRUE),
    fund_anos_fin = sum(IN_FUND_AF, na.rm = TRUE),
    ensino_medio = sum(IN_MED, na.rm = TRUE),
    eja = sum(IN_EJA, na.rm = TRUE),
    profissional = sum(IN_PROF, na.rm = TRUE),
    .groups = "drop"
  )

# Converte explicitamente para data.frame
gold_etapas_rede <- as.data.frame(gold_etapas_rede)

# KPI 4 - Escolas rurais por UF
log_msg("Calculando KPI 4: Escolas rurais por UF...")

gold_rural_uf <- df_silver |>
  group_by(NO_REGIAO, SG_UF, NO_UF, TP_LOCALIZACAO) |>
  summarise(total_escolas = n(), .groups = "drop") |>
  tidyr::pivot_wider(
    names_from = TP_LOCALIZACAO,
    values_from = total_escolas,
    values_fill = 0
  ) |>
  mutate(
    total = Rural + Urbana,
    pct_rural = round(Rural / total * 100, 1)
  ) |>
  arrange(desc(pct_rural))

# KPI 5 - Infraestrutura por localização
log_msg("Calculando KPI 5: Infraestrutura por localização")

gold_infra_localizacao <- df_silver |>
  group_by(TP_LOCALIZACAO) |>
  summarise(
    total_escolas = n(),
    pct_biblioteca = round(sum(IN_BIBLIOTECA, na.rm = TRUE) / n() * 100, 1),
    pct_lab_info = round(sum(IN_LABORATORIO_INFORMATICA, na.rm = TRUE) / n() * 100, 1),
    pct_lab_ciencias = round(sum(IN_LABORATORIO_CIENCIAS, na.rm = TRUE) / n() * 100, 1),
    pct_quadra = round(sum(IN_QUADRA_ESPORTES, na.rm = TRUE) / n() * 100, 1),
    pct_internet = round(sum(IN_INTERNET, na.rm = TRUE) / n() * 100, 1),
    pct_banda_larga = round(sum(IN_BANDA_LARGA, na.rm = TRUE) / n() * 100, 1),
    .groups = "drop"
  )

# Garante que todos os data frames Gold têm apenas tipos simples
colecoes_gold <- lapply(colecoes_gold, function(df) {
  df <- as.data.frame(df)
  df |> mutate(across(where(is.numeric), as.numeric),
               across(where(is.character), as.character))
})

# Salvando no MongoDB - Coleções Gold
log_msg("Salvando coleções Gold no MongoDB...")

colecoes_gold <- list(
  gold_uf_dependencia = gold_uf_dependencia,
  gold_internet_uf = gold_internet_uf,
  gold_etapas_rede = gold_etapas_rede,
  gold_rural_uf = gold_rural_uf,
  gold_infra_localizacao = gold_infra_localizacao
)
  
for (nome in names(colecoes_gold)) {
  con <- mongo_connect(nome)
  con$remove("{}")
  con <- mongo_connect(nome)
  con$insert(colecoes_gold[[nome]])
  log_msg(paste("Coleção salva:", nome, "| Documentos:", con$count()))
}

log_msg("Gold concluído!")

# Preview dos resultados
cat("\n--- KPI 1: Top 5 UFs por total de escolas ---\n")

gold_uf_dependencia |>
  group_by(SG_UF) |>
  summarise(total = sum(total_escolas)) |>
  slice_max(total, n = 5) |>
  print()

cat("\n--- KPI 2: Top 5 UFs em banda larga ---\n")
gold_internet_uf |> slice_max(pct_banda_larga, n = 5) |>
  select(SG_UF, total_escolas, pct_banda_larga) |> print()

cat("\n--- KPI 5: Infraestrutura Urbana vs Rural ---\n")
print(gold_infra_localizacao)