# Insumos que nao existem no FTP do IBGE.
#
# Sao as amostras preparadas de 1960, 1970, 1980 e 1991 -- onde a versao do FTP
# ou nao existe (1960), ou e pior que a preparada (1980 perde V518/V3/V4/V6,
# 1991 perde a V0102), ou esta corrompida na origem (1970: 1.785 registros
# deslocados em AL e PE) -- mais os crosswalks.
#
# O crosswalk_munic_1970_to_2010.rda era da rota antiga de 1970, pelo FWF do
# FTP, e hoje nao e usado por nenhuma funcao; fica no release como parte do
# acervo.
#
# Ficam num release proprio do repo, `release_legacy`. Enquanto ele nao esta
# publicado, o pipeline usa o espelho local em data/release_legacy/, que e
# onde os arquivos sao montados. O codigo e o mesmo nos dois casos: quem chama
# recebe os caminhos e nao precisa saber de onde vieram.


release_legacy_url <- "https://github.com/ipea/censobr_prep_data/releases/download/release_legacy/"


# Devolve os caminhos dos arquivos pedidos, do espelho local se houver, senao
# baixando do release.
get_release_legacy <- function(files, dest_dir){

  local <- file.path("./data/release_legacy", files)
  if(all(file.exists(local))){
    message("  usando o espelho local do release_legacy")
    return(local)
  }

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  download_file_censobr(file_url = paste0(release_legacy_url, files),
                        dest_dir = dest_dir,
                        max_active = 1)

  baixados <- file.path(dest_dir, files)
  if(!all(file.exists(baixados)))
    stop("Faltou input do release_legacy: ",
         paste(files[!file.exists(baixados)], collapse = ", "))

  baixados
}
