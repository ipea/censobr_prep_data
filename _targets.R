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
  
  # A versao publica anterior e a v0.6.0. O salto de numero e proporcional ao
  # que mudou desde ela: 1960 deixou de ser a compilacao antiga, que nunca fora
  # auditada, e passou a sair da reconstrucao dos dois arquivos brutos -- duas
  # tabelas novas, de 66 e 98 colunas, com os pesos calibrados aos resultados
  # definitivos da Serie Nacional e o desenho amostral de verdade; 1970 trocou
  # de fonte (FTP -> versao CEM no release_legacy); o shift de SP em pessoa02 de
  # 2010 foi corrigido; 1980 mudou code_muni, V602, V212 e V213; entrou a
  # amostra publica de 2022; e os setores preliminares de 2022 recuperaram
  # 15.969.053 pessoas que o inner join com o basico definitivo descartava.
  tar_target(name = data_version,
             command = "v1.0.0"
             ),
  
  
  # 01a. microdata 1960 -- amostra de 1,27%, do arquivo bruto -------------------------
  #
  # Reconstrucao passo a passo da amostra de 1,27% (ver R/microdata_1960_amostra_127.R).
  # Os read guides e o CSV de decisoes manuais sao inputs rastreados: qualquer
  # mudanca neles refaz o que depende deles.
  tar_target(name = raw_1960_amostra_127,
             command = download_1960_amostra_127(),
             format = "file"
             ),

  tar_target(name = guia_1960_amostra_127_familias,
             command = "read_guides/readguide_1960_amostra_127_familias.csv",
             format = "file"
             ),

  tar_target(name = guia_1960_amostra_127_pessoas,
             command = "read_guides/readguide_1960_amostra_127_pessoas.csv",
             format = "file"
             ),

  tar_target(name = correcoes_1960_amostra_127,
             command = "read_guides/1960_amostra_127_correcoes.csv",
             format = "file"
             ),

  # as linhas do arquivo, intactas
  tar_target(name = linhas_1960_amostra_127,
             command = read_1960_amostra_127(raw_1960_amostra_127)
             ),

  # as linhas suspeitas, com o resultado dos quatro testes, e a conferencia de
  # que cada uma tem decisao escrita
  tar_target(name = problemas_1960_amostra_127,
             command = detect_1960_amostra_127(linhas_1960_amostra_127,
                                               guia_1960_amostra_127_familias,
                                               guia_1960_amostra_127_pessoas,
                                               correcoes_1960_amostra_127)
             ),

  # as linhas depois das decisoes (depende de problemas_ so para garantir a ordem)
  tar_target(name = linhas_corrigidas_1960_amostra_127,
             command = {
               problemas_1960_amostra_127
               apply_corrections_1960_amostra_127(linhas_1960_amostra_127, correcoes_1960_amostra_127)
             }
             ),

  # layout aplicado: lista com familias e pessoas, ainda em texto
  tar_target(name = tabelas_brutas_1960_amostra_127,
             command = parse_1960_amostra_127(linhas_corrigidas_1960_amostra_127,
                                              guia_1960_amostra_127_familias,
                                              guia_1960_amostra_127_pessoas)
             ),

  # duplicatas de Pernambuco removidas
  tar_target(name = tabelas_dedup_1960_amostra_127,
             command = dedup_1960_amostra_127(tabelas_brutas_1960_amostra_127)
             ),

  # familias pela chave do questionario, domicilios por V101, Rondonia devolvida
  tar_target(name = familias_1960_amostra_127,
             command = build_families_1960_amostra_127(tabelas_dedup_1960_amostra_127)
             ),

  # divisao territorial de 1960 com a populacao do AEB: nome do municipio e o criterio de cidade grande
  tar_target(name = municipios_1960,
             command = "./read_guides/1960_municipios.csv",
             format = "file"
             ),

  # distritos, e os bairros, circunscricoes e favelas da Guanabara, do Codigo de Municipios e Distritos de 1960
  tar_target(name = distritos_1960,
             command = "./read_guides/1960_distritos.csv",
             format = "file"
             ),

  # contagens, peso uniforme, codigos, marcas de coerencia, tipos, desenho da amostra
  tar_target(name = tabelas_1960_amostra_127,
             command = finalize_1960_amostra_127(familias_1960_amostra_127, municipios_1960, distritos_1960)
             ),

  # quadros 1 e 6 dos Resultados Preliminares de 1965, transcritos e conferidos
  tar_target(name = gabarito_1960_1965,
             command = "./references/censo_1960_resultados_preliminares_1965.csv",
             format = "file"
             ),

  # tabelas por UF dos resultados definitivos (Serie Nacional, vol. I), transcritas e conferidas
  tar_target(name = gabarito_1960_definitivos,
             command = "./references/censo_1960_resultados_definitivos_serie_nacional.csv",
             format = "file"
             ),

  # pesos de domicilio: censobr_weight calibrado aos definitivos, censobr_weight_1965 ao quadro 1 de 1965
  tar_target(name = tabelas_calibradas_1960_amostra_127,
             command = calibrate_1960_amostra_127(tabelas_1960_amostra_127, gabarito_1960_1965, gabarito_1960_definitivos)
             ),

  # reproducao dos sete quadros de 1965 e das tabelas definitivas, com cada um dos dois pesos
  tar_target(name = validacao_1965_1960_amostra_127,
             command = validate_1965_1960_amostra_127(tabelas_calibradas_1960_amostra_127, gabarito_1960_1965)
             ),

  tar_target(name = validacao_definitivos_1960_amostra_127,
             command = validate_definitivos_1960_amostra_127(tabelas_calibradas_1960_amostra_127, gabarito_1960_definitivos)
             ),

  # erros amostrais pelo desenho de pastas: o que a publicacao especial de 1965 daria
  tar_target(name = erros_1960_amostra_127,
             command = sampling_errors_1960_amostra_127(tabelas_calibradas_1960_amostra_127, gabarito_1960_definitivos)
             ),

  tar_target(name = output_1960_amostra_127,
             command = save_1960_amostra_127(tabelas_calibradas_1960_amostra_127),
             format = "file"
             ),

  # 01b. microdata 1960 -- amostra de 25%, dos arquivos brutos por UF -----------------

  # Sao 17 arquivos, um por UF, e 18 milhoes de registros. O eixo do branching e
  # a UF porque tudo se decompoe por ela: o municipio e a pasta aninham na UF sem
  # excecao. Cada branch grava parquet e devolve caminho, nunca a tabela -- ver
  # R/microdata_1960_amostra_25.R.
  tar_target(name = ufs_1960_amostra_25,
             command = names(UF_1960_AMOSTRA_25)
             ),

  tar_target(name = raw_1960_amostra_25,
             command = download_1960_amostra_25(),
             format = "file"
             ),

  tar_target(name = guia_1960_amostra_25_familias,
             command = "read_guides/readguide_1960_amostra_25_familias.csv",
             format = "file"
             ),

  tar_target(name = guia_1960_amostra_25_pessoas,
             command = "read_guides/readguide_1960_amostra_25_pessoas.csv",
             format = "file"
             ),

  tar_target(name = correcoes_1960_amostra_25,
             command = "read_guides/1960_amostra_25_correcoes.csv",
             format = "file"
             ),

  tar_target(name = auditoria_1960_amostra_25,
             command = audit_1960_amostra_25(raw_1960_amostra_25,
                                             ufs_1960_amostra_25,
                                             guia_1960_amostra_25_familias,
                                             guia_1960_amostra_25_pessoas,
                                             correcoes_1960_amostra_25),
             pattern = map(ufs_1960_amostra_25)
             ),

  tar_target(name = tabelas_brutas_1960_amostra_25,
             command = read_1960_amostra_25(raw_1960_amostra_25,
                                            ufs_1960_amostra_25,
                                            guia_1960_amostra_25_familias,
                                            guia_1960_amostra_25_pessoas,
                                            correcoes_1960_amostra_25,
                                            auditoria_1960_amostra_25),
             pattern = map(ufs_1960_amostra_25, auditoria_1960_amostra_25),
             format = "file"
             ),

  # o boletim e a familia: 1, 2, 3 e 9 abrem domicilio e 4 e 5 entram no anterior.
  # A geografia usa os mesmos guias do bloco 01a -- ver R/microdata_1960_amostra_25.R.
  tar_target(name = tabelas_1960_amostra_25,
             command = build_1960_amostra_25(tabelas_brutas_1960_amostra_25,
                                             ufs_1960_amostra_25,
                                             municipios_1960,
                                             distritos_1960),
             pattern = map(ufs_1960_amostra_25, tabelas_brutas_1960_amostra_25),
             format = "file"
             ),

  # uma etapa so: o domicilio e a unidade sorteada e a pasta x situacao o estrato.
  # Dois pesos -- razao a contagem completa por municipio x situacao e o metodo do
  # IBGE por UF x situacao -- ver R/microdata_1960_amostra_25.R.
  tar_target(name = pesos_1960_amostra_25,
             command = weight_1960_amostra_25(tabelas_1960_amostra_25,
                                              ufs_1960_amostra_25,
                                              municipios_1960,
                                              gabarito_1960_definitivos),
             pattern = map(ufs_1960_amostra_25, tabelas_1960_amostra_25),
             format = "file"
             ),

  # as duas validacoes agregam o pais inteiro e por isso nao sao ramificadas;
  # leem os parquets por UF e acumulam -- ver R/microdata_1960_amostra_25.R
  tar_target(name = validacao_definitivos_1960_amostra_25,
             command = validate_definitivos_1960_amostra_25(pesos_1960_amostra_25,
                                                            gabarito_1960_definitivos),
             format = "file"
             ),

  tar_target(name = erros_1960_amostra_25,
             command = sampling_errors_1960_amostra_25(pesos_1960_amostra_25),
             format = "file"
             ),

  # a unica validacao registro a registro que 1960 tem: a amostra de 1,27% e
  # subamostra desta e casa pela chave do questionario
  tar_target(name = comparacao_127_1960_amostra_25,
             command = compare_127_1960_amostra_25(pesos_1960_amostra_25,
                                                   output_1960_amostra_127[2]),
             format = "file"
             ),

  # 01c. microdata 1960 -- a compilacao das duas amostras ----------------------------
  #
  # A particao e por unidade da federacao: dezessete vem da amostra de 25% e onze
  # da de 1,27%, que nas dezessete e subamostra daquela e duplicaria gente. Um
  # branch por unidade, um parquet por unidade, e o arquivo unico so no save, por
  # streaming -- ver R/microdata_1960.R. Substitui o bloco # 01., que apenas
  # renomeava as colunas da compilacao antiga do release_legacy.
  tar_target(name = unidades_1960,
             command = c(names(UF_1960_AMOSTRA_25), names(UF_1960_AMOSTRA_127))
             ),

  # o estrato da amostra de 1,27% foi construido sobre as 28 unidades e nao
  # sobrevive ao corte: dos 75, so 23 tem pasta nas onze que ficam
  tar_target(name = estratos_1960_compilada,
             command = estratos_1960(output_1960_amostra_127[2])
             ),

  tar_target(name = compilada_1960,
             command = compile_1960(pesos_1960_amostra_25,
                                    output_1960_amostra_127,
                                    estratos_1960_compilada,
                                    unidades_1960,
                                    municipios_1960,
                                    gabarito_1960_definitivos),
             pattern = map(unidades_1960),
             format = "file"
             ),

  # as duas validacoes agregam o pais inteiro e por isso nao sao ramificadas
  tar_target(name = validacao_1960,
             command = validate_1960(compilada_1960, gabarito_1960_definitivos),
             format = "file"
             ),

  tar_target(name = erros_1960,
             command = sampling_errors_1960(compilada_1960),
             format = "file"
             ),

  # o dicionario coluna a coluna: e por ele que os nomes se conferem antes de publicar
  tar_target(name = dicionario_1960_compilada,
             command = dicionario_1960(compilada_1960,
                                       guia_1960_amostra_25_familias,
                                       guia_1960_amostra_25_pessoas),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_1960,
             command = c("households", "population")
             ),

  tar_target(name = output_microdata_1960,
             command = save_microdata_1960(compilada_1960,
                                           dataset_names_microdata_1960,
                                           data_version),
             pattern = map(dataset_names_microdata_1960),
             format = "file"
             ),


  # 02. microdata 1970 ---------------------------------------------------------------

  # a fonte e a versao CEM, no release_legacy: o FWF do FTP traz 1.785
  # registros deslocados em AL e PE -- ver R/microdata_1970.R
  tar_target(name = raw_microdata_paths_1970,
             command = download_microdata_1970(),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_1970,
             command = c("households", "population")
             ),

  # a tabela de domicilios e derivada do arquivo de pessoas, e nao lida pronta
  # do CEM -- ver R/microdata_1970.R
  tar_target(name = derived_paths_1970,
             command = derive_households_1970(raw_microdata_paths_1970),
             format = "file"
             ),

  # branch per dataset: o vinculo pessoa -> domicilio vem do crosswalk, e so
  # vale quando resolve na tabela de domicilios -- ver R/microdata_1970.R
  tar_target(name = output_microdata_1970,
             command = save_microdata_1970(
               clean_microdata_1970(raw_microdata_paths_1970,
                                    derived_paths_1970,
                                    dataset_names_microdata_1970),
               dataset_names_microdata_1970,
               data_version),
             pattern = map(dataset_names_microdata_1970),
             format = "file"
             ),


  # 03. microdata 1980 ---------------------------------------------------------------

  # input: amostra preparada pelo Rogerio, no release_legacy. O DBF do FTP
  # IBGE 2025 perde V518, V3, V4 e V6 -- ver R/microdata_1980.R.
  tar_target(name = raw_microdata_paths_1980,
             command = download_microdata_1980(),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_1980,
             command = c("households", "population")
             ),

  # branch per dataset: clean e save no mesmo target (pessoas tem 29,4M linhas)
  tar_target(name = output_microdata_1980,
             command = save_microdata_1980(
               clean_microdata_1980(raw_microdata_paths_1980,
                                    dataset_names_microdata_1980),
               dataset_names_microdata_1980,
               data_version),
             pattern = map(dataset_names_microdata_1980),
             format = "file"
             ),


  # 04. microdata 1991 ---------------------------------------------------------------

  # input: amostra preparada pelo Rogerio, no release_legacy. O DBF do FTP
  # IBGE nao traz a V0102 -- ver R/microdata_1991.R.
  tar_target(name = raw_microdata_paths_1991,
             command = download_microdata_1991(),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_1991,
             command = c("households", "population")
             ),

  # branch per dataset: clean e save no mesmo target (pessoas tem 17M linhas)
  tar_target(name = output_microdata_1991,
             command = save_microdata_1991(
               clean_microdata_1991(raw_microdata_paths_1991,
                                    dataset_names_microdata_1991),
               dataset_names_microdata_1991,
               data_version),
             pattern = map(dataset_names_microdata_1991),
             format = "file"
             ),


  # 05. microdata 2000 ---------------------------------------------------------------

  # download (also unzips, inclusive os zips aninhados da Bahia).
  tar_target(name = raw_microdata_paths_2000,
             command = download_microdata_2000(),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_2000,
             command = c("households", "population", "families")
             ),

  # branch per table: parse FWF por UF com staging, empilha e grava
  tar_target(name = output_microdata_2000,
             command = save_microdata_2000(
               clean_microdata_2000(raw_microdata_paths_2000,
                                    dataset_names_microdata_2000),
               dataset_names_microdata_2000,
               data_version),
             pattern = map(dataset_names_microdata_2000),
             format = "file"
             ),

  # 06. microdata 2010 ---------------------------------------------------------------

  # download (also unzips). Returns paths to all extracted TXTs.
  tar_target(name = raw_microdata_paths_2010,
             command = download_microdata_2010(),
             format = "file"
             ),

  tar_target(name = dataset_names_microdata_2010,
             command = c("households", "population", "mortality", "emigration")
             ),

  # branch per table: parse FWF por UF com staging, empilha e grava
  tar_target(name = output_microdata_2010,
             command = save_microdata_2010(
               clean_microdata_2010(raw_microdata_paths_2010,
                                    dataset_names_microdata_2010),
               dataset_names_microdata_2010,
               data_version),
             pattern = map(dataset_names_microdata_2010),
             format = "file"
             ),


  # 07. microdata 2022 ---------------------------------------------------------------

  # amostra de ACESSO PUBLICO (nivel 1) -- a unica redistribuivel. O acesso
  # controlado (nivel 2) e importado pelo proprio pesquisador no consumidor.

  # download (also unzips). Returns paths to all extracted CSVs.
  tar_target(name = raw_microdata_paths_2022,
             command = download_microdata_2022(),
             format = 'file'
             ),

  tar_target(name = dataset_names_microdata_2022,
             command = c("households", "population", "families", "mortality")
             ),

  # branch per table: clean e save no mesmo target -- Pessoas tem 21,5M linhas,
  # e um target intermediario obrigaria o targets a serializar isso em
  # _targets/objects/. A query arrow atravessa os dois passos preguicosa.
  tar_target(name = output_microdata_2022,
             command = save_microdata_2022(
               clean_microdata_2022(raw_microdata_paths_2022,
                                    dataset_names_microdata_2022),
               dataset_names_microdata_2022,
               data_version),
             pattern = map(dataset_names_microdata_2022),
             format = 'file'
             ),

  # 08. census tracts 2000 ---------------------------------------------------------------

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

  # 09. census tracts 2010 ---------------------------------------------------------------
  
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

  # 10. census tracts 2022 ---------------------------------------------------------------

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
             ),

  # 11. tracts 2022 preliminares ------------------------------------------------------

  # divulgacao previa do Censo 2022, um CSV nacional unico -- ver
  # R/census_tracts_2022_prelim.R
  tar_target(name = raw_tracts_path_2022_prelim,
             command = download_tract_2022_prelim(),
             format = 'file'
             ),

  tar_target(name = clean_tract_2022_prelim,
             command = clean_tracts_2022_prelim(raw_tracts_path_2022_prelim)
             ),

  tar_target(name = output_tracts_path_2022_prelim,
             command = save_tracts_2022_prelim(clean_tract_2022_prelim, data_version),
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
  
  # Upload to GitHub Releases (requires GITHUB_TOKEN in ~/.Renviron).
  # O upload e feito fora do tar_make, so no fim, e nunca por um agente:
  # tar_target(name = upload,
  #            command = piggyback::pb_upload(file = c(output_microdata_1970, ...),
  #                                           repo = "ipea/censobr",
  #                                           tag  = data_version)
  # )
)

