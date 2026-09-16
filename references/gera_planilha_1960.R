# Atualiza as duas abas de conteudo da planilha de variaveis de 1960 que o
# censobr publica no release `censo_docs`, a partir da forma tabular que
# references/gera_dicionario_1960.py emite.
#
# A planilha e o workbook de origem dos dois HTML, e traz sete abas que a
# exportacao para HTML nao leva: as seis listas longas (v207, v210, v214, v216,
# v221, v223b) e o crosswalk de municipio. Essas ficam intactas -- so as abas
# Pessoas e Domicilios sao reescritas.
#
# Roda da raiz do projeto, depois do gerador dos HTML:
#   Rscript references/gera_planilha_1960.R

library(openxlsx)
library(data.table)

molde <- "references/censo_docs/molde/1960_dictionary_microdata.xlsx"
saida <- "references/censo_docs/1960_dictionary_microdata.xlsx"

wb <- loadWorkbook(molde)
ordem <- sheets(wb)
message("abas no molde: ", paste(ordem, collapse = ", "))

titulo <- c(Domicilios = "Dicionário de variáveis da Amostra Censo Demográfico de 1960 - Domicílios\nMicrodados da Amostra Compilada (1,27% e 25%)",
            Pessoas    = "Dicionário de variáveis da Amostra Censo Demográfico de 1960 - Pessoas\nMicrodados da Amostra Compilada (1,27% e 25%)")
fonte <- c(Domicilios = "households", Pessoas = "population")

# os estilos do molde: titulo, cabecalho, secao e celula
est_titulo  <- createStyle(fontSize = 12, textDecoration = "bold", halign = "center",
                           valign = "center", wrapText = TRUE)
est_cabec   <- createStyle(fontSize = 10, textDecoration = "bold", halign = "center",
                           valign = "center", border = "TopBottomLeftRight", wrapText = TRUE)
est_secao   <- createStyle(fontSize = 10, textDecoration = "bold", halign = "left",
                           valign = "center", fgFill = "#D9D9D9", border = "TopBottomLeftRight")
est_var     <- createStyle(fontSize = 10, halign = "center", valign = "center",
                           border = "TopBottomLeftRight", wrapText = TRUE)
est_rotulo  <- createStyle(fontSize = 10, halign = "left", valign = "center",
                           border = "TopBottomLeftRight", wrapText = TRUE)

for(aba in names(fonte)){
  d <- fread(file.path("references/censo_docs",
                       paste0("1960_dictionary_microdata_", fonte[[aba]], ".csv")),
             encoding = "UTF-8", colClasses = "character")

  removeWorksheet(wb, aba)
  addWorksheet(wb, aba)

  # linha 1: o titulo, nas quatro colunas
  writeData(wb, aba, titulo[[aba]], startRow = 1, startCol = 1, colNames = FALSE)
  mergeCells(wb, aba, cols = 1:4, rows = 1)
  addStyle(wb, aba, est_titulo, rows = 1, cols = 1:4, gridExpand = TRUE)
  setRowHeights(wb, aba, 1, 38)

  # linhas 2 e 3: o cabecalho de duas alturas
  writeData(wb, aba, data.frame(a = "Nome da Variável", b = "Rótulo da Variável",
                                c = "Categorias", d = NA),
            startRow = 2, startCol = 1, colNames = FALSE)
  writeData(wb, aba, data.frame(c = "Código", d = "Descrição"),
            startRow = 3, startCol = 3, colNames = FALSE)
  mergeCells(wb, aba, cols = 1, rows = 2:3)
  mergeCells(wb, aba, cols = 2, rows = 2:3)
  mergeCells(wb, aba, cols = 3:4, rows = 2)
  addStyle(wb, aba, est_cabec, rows = 2:3, cols = 1:4, gridExpand = TRUE)

  # o corpo
  linha <- 4L
  for(i in seq_len(nrow(d))){
    tipo <- d$tipo_linha[i]
    if(tipo %in% c("secao", "subsecao")){
      writeData(wb, aba, d$variavel[i], startRow = linha, startCol = 1, colNames = FALSE)
      mergeCells(wb, aba, cols = 1:4, rows = linha)
      addStyle(wb, aba, est_secao, rows = linha, cols = 1:4, gridExpand = TRUE)
    } else {
      writeData(wb, aba, data.frame(a = d$variavel[i], b = d$rotulo[i],
                                    c = d$codigo[i], e = d$descricao[i]),
                startRow = linha, startCol = 1, colNames = FALSE)
      addStyle(wb, aba, est_var,    rows = linha, cols = 1,   gridExpand = TRUE)
      addStyle(wb, aba, est_rotulo, rows = linha, cols = 2,   gridExpand = TRUE)
      addStyle(wb, aba, est_var,    rows = linha, cols = 3,   gridExpand = TRUE)
      addStyle(wb, aba, est_rotulo, rows = linha, cols = 4,   gridExpand = TRUE)
    }
    linha <- linha + 1L
  }

  setColWidths(wb, aba, cols = 1:4, widths = c(26, 58, 13, 52))
  freezePane(wb, aba, firstActiveRow = 4)
  message("  ", aba, ": ", nrow(d), " linhas")
}

worksheetOrder(wb) <- match(ordem, sheets(wb))
saveWorkbook(wb, saida, overwrite = TRUE)
message("gravado: ", saida, " (", file.size(saida), " bytes)")
