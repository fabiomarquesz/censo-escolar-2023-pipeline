
#Funções auxiliares do pipeline

library(mongolite)
library(dotenv)

#Carrega variáveis do .env
load_dot_env(".env")

#Função de conexão com MongoDB
mongo_connect <- function(collection) {
  mongolite::mongo(
    collection = collection,
    db = Sys.getenv("MONGO_DB"),
    url = Sys.getenv("MONGO_URI")
  )
}

#Função de log simples com timestamp
log_msg <- function(msg) {
  cat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S]"), msg, "\n")
}