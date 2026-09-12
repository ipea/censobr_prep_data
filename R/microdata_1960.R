# 1960 microdata sample (amostra compilada).
# Os arquivos brutos do censo de 1960 nao estao no FTP do IBGE; o input deste
# pipeline eh uma amostra ja compilada pelo Rogerio (combinando as amostras
# 1.27% e 25%), hospedada no release `release_legacy` deste repo. Documentacao
# do compilado em censoBR_aux_Dados/1960/.../Criando a amostra compilada/.
#
# Pipeline minimo: baixa os 2 parquets, renomeia cols v* -> V* (consumer
# censobr espera maiusculo), aplica convencao v0.6.0 em code_* (numeric) e
# salva. Nao adiciona geo cols (paridade rigida com v0.5.0 -- que tambem so
# traz `uf` e `code_muni_1960` do compilado).
#
# Public API: download_microdata_1960, clean_microdata_1960, save_microdata_1960.


# Baixa os 2 inputs do release_legacy (smart-skip via download_file_censobr).
download_microdata_1960 <- function(){

  dest_dir <- "./data_raw/microdata/1960"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  message("\nDownloading 1960 microdata (release_legacy)...\n")

  get_release_legacy(c("Censo.1960.brasil.domicilios.amostraCompilada.censobr.parquet",
                       "Censo.1960.brasil.pessoas.amostraCompilada.censobr.parquet"),
                     dest_dir)
}


# le um dos 2 datasets e renomeia v* -> V*. Inclui dataset_name como sentinela
# pra save dispatch.
clean_microdata_1960 <- function(raw_paths, dataset_name){

  message("Cleaning microdata 1960: ", dataset_name)

  tbl_file <- switch(dataset_name,
                     households = "domicilios",
                     population = "pessoas")

  df <- arrow::read_parquet(raw_paths[grepl(tbl_file, basename(raw_paths))])

  # consumer censobr espera prefixo V maiusculo nos codigos do questionario
  names(df) <- ifelse(startsWith(names(df), "v"), sub("^v", "V", names(df)), names(df))

  df$dataset_name <- dataset_name
  df
}


save_microdata_1960 <- function(cleaned_df, data_version){

  ds <- cleaned_df$dataset_name[1]
  message("Saving microdata 1960: ", ds)

  out <- cleaned_df
  out$dataset_name <- NULL

  # convencao v0.6.0: code_* numeric (afeta code_muni_1960; quebra intencional
  # vs v0.5.0 onde era int32).
  out <- code_cols_to_numeric(out)

  dir.create("./data/microdata_sample/1960/", recursive = TRUE, showWarnings = FALSE)
  dest_file <- paste0("./data/microdata_sample/1960/1960_", ds, "_", data_version, ".parquet")
  write_censobr_parquet(out, dest_file)

  dest_file
}
