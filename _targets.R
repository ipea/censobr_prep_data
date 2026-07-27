library(targets)
library(tarchetypes)
library(crew)

# cores available
# coress <- floor(.9 * parallelly::freeCores()[1])
coress <- 1  # limitado temporariamente para evitar rate-limit do FTP IBGE


# RENV -------------------------------------------------------------------------

# # See if the packages are updated:
# renv::status()
# # Update packages if needed:
# renv::snapshot()

# Set target options: ----------------------------------------------------------
tar_option_set(
  format = "rds",
  memory = "transient",
  garbage_collection = TRUE,
  # crew_controller_local on Windows can fail to respawn workers between tasks
  # ("callr subprocess failed: could not start R") after default seconds_idle=300.
  # Keeping the worker alive for the whole pipeline (seconds_idle = Inf) avoids
  # repeated callr respawns, which is the root cause of the crash.
  # See deferred_priorities for follow-up investigation. With coress = 1 this
  # still serializes targets; we lose nothing.
  controller = crew_controller_local(
    workers = coress,
    seconds_idle = Inf,
    options_local = crew_options_local(log_directory = "./logs/crew_workers")
  ),
  storage = "worker" ,
  retrieval = "worker",
  trust_timestamps = TRUE,
  # error = "null",
  
  # Packages essentials --------------------------------------------------------
  packages = c('arrow',
               'crew',
               'data.table',
               'dplyr',
               'duckdb',
               'httr2',
               'igraph',
               'rvest',
               'janitor',
               'magrittr',
               'mirai',
               'openxlsx',
               'parallelly',
               'parallel',
               'pbapply',
               'piggyback',
               'purrr',
               'RCurl',
               'curl',
               'readr',
               'readxl',
               'stringi',
               'stringr',
               'tarchetypes',
               'tibble',
               'tidyverse',
               'utils',
               'varhandle',
               'visNetwork',
               'future',
               'furrr'
  )
)

# invisible(lapply(packages, library, character.only = TRUE))

# tar_make_clustermq() configuration (okay to leave alone):
# options(clustermq.scheduler = "multisession")

# Run the R scripts in the R/ folder with your custom functions:
targets::tar_source('./R')

############# The Targets List #########----------------------------------------

# In case of error, run:
# test_errors <- targets::tar_meta(fields = warnings, complete_only = TRUE)

list(
  
  tar_target(name = data_version,
             command = "v0.6.0"
             ),
  
  
  # # 01. microdata 1960 ---------------------------------------------------------------
  # 
  # # input: amostra compilada pelo Rogerio em censoBR_aux_Dados (fora do FTP IBGE).
  # tar_target(name = aux_microdata_1960_paths,
  #            command = c(
  #              "../censoBR_aux_Dados/1960/microdados da amostra/Censo.1960.brasil.domicilios.amostraCompilada.censobr.fst",
  #              "../censoBR_aux_Dados/1960/microdados da amostra/Censo.1960.brasil.pessoas.amostraCompilada.censobr.parquet"
  #            ),
  #            format = "file"
  #            ),
  # 
  # tar_target(name = dataset_names_microdata_1960,
  #            command = c("households", "population")
  #            ),
  # 
  # # branch per dataset: read fst/parquet, rename v* -> V*, attach dataset sentinel
  # tar_target(name = clean_microdata_table_1960,
  #            command = clean_microdata_1960(aux_microdata_1960_paths, dataset_names_microdata_1960),
  #            pattern = map(dataset_names_microdata_1960)
  #            ),
  # 
  # # branch per dataset: cast code_* to numeric (v0.6.0 convention) + save parquet
  # tar_target(name = output_microdata_1960,
  #            command = save_microdata_1960(clean_microdata_table_1960),
  #            pattern = map(clean_microdata_table_1960),
  #            format = "file"
  #            ),

  # 02. microdata 1970 ---------------------------------------------------------------
  
  
  # 03. microdata 1980 ---------------------------------------------------------------
  
  # 04. microdata 1991 ---------------------------------------------------------------
  
  # 05. microdata 2010 ---------------------------------------------------------------
  
  # 06. microdata 2022 ---------------------------------------------------------------
  
  # 07. census tracts 2000 ---------------------------------------------------------------

  # download (also unzips). Returns paths to all extracted XLSs.
  tar_target(name = raw_tracts_paths_2000,
             command = download_tract_2000(),
             format = 'file'
             ),

  tar_target(name = table_names_tracts_2000,
             command = c("Basico",
                         "Domicilio",
                         "Morador",
                         "Responsavel",
                         "Pessoa",
                         "Instrucao")
             ),

  # branch per theme: read XLS per UF, recode, prefix V cols, join, attach geo
  tar_target(name = clean_tract_table_2000,
             command = clean_tracts_2000(raw_tracts_paths_2000, table_names_tracts_2000),
             pattern = map(table_names_tracts_2000)
             ),

  # branch per theme: cast code_* to numeric (v0.6.0 convention) + save parquet
  tar_target(name = output_tracts_paths_2000,
             command = save_tracts_2000(clean_tract_table_2000, data_version),
             pattern = map(clean_tract_table_2000),
             format = 'file'
             ),

  # 08. census tracts 2010 ---------------------------------------------------------------
  
  # # year input
  # tar_target(name = years_tracts,
  #            command = c(2010)),
  
  # download
  tar_target(name = raw_tracts_paths_2010,
             command = download_tract_2010(2010),
             format = 'file'
             ),
  
  tar_target(name = table_names_tracts,
             command = c(
               "BASICO", 
               "DOMICILIO", 
               "DOMICILIORENDA", 
               "ENTORNO", 
               "PESSOA", 
               "PESSOARENDA", 
               "RESPONSAVEL", 
               "RESPONSAVELRENDA"
               )
             ),
  
  # generate national table
  tar_target(name = clean_tract_table_2010,
             command = clean_tracts_2010(raw_tracts_paths_2010, table_names_tracts),
             pattern = map(table_names_tracts)
             ),
  
  # create national files: 1 parquet file for each table
  # add geography columns and save parquet
  tar_target(name = output_tracts_paths_2010,
             command = save_tracts_2010(clean_tract_table_2010, data_version),
             pattern = map(clean_tract_table_2010),
             format = 'file'
             ),

  # 09. census tracts 2022 ---------------------------------------------------------------

  # download (also unzips). Returns paths to all extracted CSVs.
  tar_target(name = raw_tracts_paths_2022,
             command = download_tract_2022(),
             format = 'file'
             ),

  tar_target(name = table_names_tracts_2022,
             command = c("Basico",
                         "Domicilio",
                         "Pessoas",
                         "ResponsavelRenda",
                         "Indigenas",
                         "Quilombolas",
                         "Entorno",
                         "Obitos")
             ),

  # branch per theme: read CSVs, recode, join multi-file themes, attach geo
  tar_target(name = clean_tract_table_2022,
             command = clean_tracts_2022(raw_tracts_paths_2022, table_names_tracts_2022),
             pattern = map(table_names_tracts_2022)
             ),

  # branch per theme: cast code_* to numeric (v0.6.0 convention) + save parquet
  tar_target(name = output_tracts_paths_2022,
             command = save_tracts_2022(clean_tract_table_2022, data_version),
             pattern = map(clean_tract_table_2022),
             format = 'file'
             )
  
  
  #END. Upload files -----------------------------------------------------------
  
  # # all files input
  # tar_target(name = all_files,
  #            command = c(
  #              # clean_tracts_paths
  #              clean_tracts_paths
  #            )),
  # 
  # tar_target(name = versao_dados,
  #            command = "v2.0.0"
  # ),
  
  # Upload to GitHub Releases (requires GITHUB_TOKEN in ~/.Renviron)
  # Sys.setenv(GITHUB_TOKEN = "ghp_...") or add to ~/.Renviron
  # tar_target(name = upload,
  #            command = upload_arquivos(files = all_files, versao_dados)
  # )
)

