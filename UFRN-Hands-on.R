---
  title: "UFRN-Hands-On"
author: "Belmiro N. Joao"
date: "17 de novembro de 2019"
output: html_document
---
  
#```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
#```

# 1. Carregando as Bibliotecas para o processamento (tm, qdap)  
#```{r}
library(tm)              # Framework for text mining.
library(qdap)            # Quantitative discourse analysis of transcripts.
library(qdapDictionaries)
library(dplyr)           # Data wrangling, pipe operator %>%().
library(RColorBrewer)    # Generate palette of colours for plots.
library(ggplot2)         # Plot word frequencies.
library(scales)          # Include commas in numbers.
library(Rgraphviz)       # Correlation plots.

#```
# mais bibliotecas
#```{r}
library(magrittr)         #
library(stringr)
#```

# 1.1 o Corpus - Fontes e Leitura
#```{r}
## ----list_sources--------------------------------------------------------
getSources()

## ----list_readers, out.lines=NULL----------------------------------------
getReaders()
#```
# 1.2 Documentos de Texto (.txt)
#```{r}
# vide diretório... algo como ... C:\Users\Joao\Downloads\corpus\txt
# os arquivos .txt estão contidos TODOS nesse diretório
## ----location_of_txt_docs------------------------------------------------
cname <- file.path(".", "corpus", "txt")
cname

## ----folder_of_txt_docs--------------------------------------------------
length(dir(cname))
dir(cname)

## ----load_corpus---------------------------------------------------------
#library(tm)
docs <- Corpus(DirSource(cname))
docs
class(docs)
class(docs[[1]])
summary(docs)

#```

# 1.3 Caso seja a leitura em PDF ou Word
#```{r}
## ----read_pdf, eval=FALSE------------------------------------------------
## docs <- Corpus(DirSource(cname), readerControl=list(reader=readPDF))

## ----read_doc, eval=FALSE------------------------------------------------
## docs <- Corpus(DirSource(cname), readerControl=list(reader=readDOC))

## ----read_doc_options, eval=FALSE----------------------------------------
## docs <- Corpus(DirSource(cname), readerControl=list(reader=readDOC("-r -s")))
#```
# 2. Explorando o Corpus
#```{r}
inspect(docs[16])
#```
# 3. Preparando o Corpus
#```{r}
getTransformations()
#```


# 3.1 Transformação Simples
#```{r}
toSpace <- content_transformer(function(x, pattern) gsub(pattern, " ", x))
docs <- tm_map(docs, toSpace, "/")
docs <- tm_map(docs, toSpace, "@")
docs <- tm_map(docs, toSpace, "\\|")
#```

#```{r}
inspect(docs[16])

#```
# 3.2 Conversão para Lower Case (caixa baixa)
#```{r}

docs <- tm_map(docs, content_transformer(tolower))
#```

#```{r}
inspect(docs[16])
#```
# 3.3 Remover Números

#```{r}
docs <- tm_map(docs, removeNumbers)
head(docs,1)
#```

# 3.4 Removar Pontuação
#```{r}
## ------------------------------------------------------------------------
docs <- tm_map(docs, removePunctuation)

head(docs,2)
#```
# 3.5 Remover stop words em inglês

#```{r}

docs <- tm_map(docs, removeWords, stopwords("english"))

inspect(docs[16])

length(stopwords("english"))
stopwords("english")
#```
# 3.6 Remova suas próprias stop words
#```{r}
# As palavras devem estar de acordo com o documento de análise 
# department e email sem ação neste caso
docs <- tm_map(docs, removeWords, c("department", "email")) #não se aplica aqui
#```
# 3.7 Strip whitespaces
#```{r}
docs <- tm_map(docs, stripWhitespace)
#```

# 3.8 Transformações Específicas
#```{r}
toString <- content_transformer(function(x, from, to) gsub(from, to, x))
# Não se aplica neste caso
docs <- tm_map(docs, toString, "harbin institute technology", "HIT")
docs <- tm_map(docs, toString, "shenzhen institutes advanced technology", "SIAT")
docs <- tm_map(docs, toString, "chinese academy sciences", "CAS")

inspect(docs[16])
#```
# 3.9 Stemming
#```{r}
docs <- tm_map(docs, stemDocument)
#```
# 4. Criando um DTM (Document Term Matrix)
#```{r}
# Uma matriz de termo de documento (dtm) é uma matriz matemática que descreve a frequência de termos que ocorrem em uma coleção de documentos. 
# Em uma dtm as linhas correspondem aos documentos na coleção e as colunas correspondem aos termos.
dtm <- DocumentTermMatrix(docs)

dtm
inspect(dtm[1:5, 1000:1005])

class(dtm)
dim(dtm)

tdm <- TermDocumentMatrix(docs)
tdm
#```

# 5. Explorando o DTM (Document Term Matrix)
#```{r}

freq <- colSums(as.matrix(dtm))
length(freq)

ord <- order(freq)

freq[head(ord)]

freq[tail(ord)]
#```

# 6. Distribuição da Frequencia de Termos
#```{r}
head(table(freq), 15)
tail(table(freq), 15)
#```
# 7. Conversão para Matrix e Salvar em Formato CSV
#```{r}

m <- as.matrix(dtm)
dim(m)

write.csv(m, file="dtm.csv") # Matriz gravada 
#```
# 8. Remover Termos Sparse
#```{r}

dim(dtm)
dtms <- removeSparseTerms(dtm, 0.1)
dim(dtms)

inspect(dtms)

freq <- colSums(as.matrix(dtms))
freq
table(freq)
#```
# 9. Identificar Itens e Associaçãoes Frequentes
#```{r}
findFreqTerms(dtm, lowfreq=100) #era 1000

findFreqTerms(dtm, lowfreq=10) #era 100

findAssocs(dtm, "data", corlimit=0.6)
#```
# 10. Plotar Correlações
#```{r}
plot(dtm, 
     terms=findFreqTerms(dtm, lowfreq=5)[1:20], # aqui 25
     corThreshold=0.5)
#```
# 11. Plotar Correlações (Opções)
#```{r}
plot(dtm, 
     terms=findFreqTerms(dtm, lowfreq=2)[1:18], # 18 para facilitar a leitura
     corThreshold=0.5,
     weighting=TRUE)
#```
# 12. Plotar Frequência das Palavras
#```{r}
freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)
head(freq, 14)
wf   <- data.frame(word=names(freq), freq=freq)
head(wf)

library(ggplot2)
subset(wf, freq>10)                                                  %>%
  ggplot(aes(word, freq))                                              +
  geom_bar(stat="identity")                                            +
  theme(axis.text.x=element_text(angle=45, hjust=1))
#```
# 13. Nuvem de Palavras
#```{r, warning=FALSE}
library(wordcloud)
set.seed(123)
wordcloud(names(freq), freq, min.freq=5)
#```

# 13.1 Reduzindo a Desordem com máximo de palavras
#```{r, warning=FALSE}
set.seed(142)
wordcloud(names(freq), freq, max.words=100)
#```
# 13.2 Reduzindo a Desordem com o mínimo de palavras
#```{r, warning=FALSE}
set.seed(142)
wordcloud(names(freq), freq, min.freq=100)
#```
# 13.3 Adicionando Cores
#```{r, warning=FALSE}
set.seed(142)
wordcloud(names(freq), freq, min.freq=100, colors=brewer.pal(6, "Dark2"))
#```
# 13.4 Variando a Escala
#```{r, warning=FALSE}
set.seed(142)
wordcloud(names(freq), freq, min.freq=100, scale=c(5, .1), colors=brewer.pal(6, "Dark2"))
#```
# 13.5 Rotacionando Palavras
#```{r, warning=FALSE}
set.seed(142)
dark2 <- brewer.pal(6, "Dark2")
wordcloud(names(freq), freq, min.freq=100, rot.per=0.2, colors=dark2)
#```
# 14. Análise Quantitativa do Texto
#```{r}
library(qdap)

words <- dtm                                                          %>%
  as.matrix                                                           %>%
  colnames                                                            %>%
  (function(x) x[nchar(x) < 20])

length(words)
head(words, 15)
summary(nchar(words))
table(nchar(words))
dist_tab(nchar(words))
#```
# 14.1 Contando o Tamanho das Palavras
#```{r}
data.frame(nletters=nchar(words))                                     %>%
  ggplot(aes(x=nletters))                                              + 
  geom_histogram(binwidth=1)                                           +
  geom_vline(xintercept=mean(nchar(words)), 
             colour="green", size=1, alpha=.5)                         + 
  labs(x="Número de Documentos", y="Número de Palavras")
#```
# 14.2 Frequência dos Documentos
#```{r}
library(dplyr)
library(stringr)

words                                                        %>%
  str_split("")                                                       %>%
  sapply(function(x) x[-1])                                           %>%
  unlist                                                              %>%
  dist_tab                                                            %>%
  mutate(Letter=factor(toupper(interval),
                       levels=toupper(interval[order(freq)])))        %>%
  ggplot(aes(Letter, weight=percent))                                  + 
  geom_bar()                                                           +
  coord_flip()                                                         +
  labs(y="Proporção")                                                   +
  scale_y_continuous(breaks=seq(0, 12, 2), 
                     label=function(x) paste0(x, "%"), 
                     expand=c(0,0), limits=c(0,12))
#```
# 14.3 Letter e Posição (Mapa de Calor)
#```{r}

words                                                                 %>%
  lapply(function(x) sapply(letters, gregexpr, x, fixed=TRUE))        %>%
  unlist                                                              %>%
  (function(x) x[x!=-1])                                              %>%
  (function(x) setNames(x, gsub("\\d", "", names(x))))                %>%
  (function(x) apply(table(data.frame(letter=toupper(names(x)), 
                                      position=unname(x))),
                     1, function(y) y/length(x)))                     %>%
  qheat(high="green", low="yellow", by.column=NULL, 
        values=TRUE, digits=3, plot=FALSE)                             +
  labs(y="Letter", x="Posição") + 
  theme(axis.text.x=element_text(angle=0))                             +
  guides(fill=guide_legend(title="Proporção"))

#```
# REVISÃO - PREPARANDO O CORPUS PARA ANÁLISE
#```{r}
## ----review_prepare_corpus, eval=FALSE-----------------------------------
## # Required packages
## 
## library(tm)
## library(wordcloud)
## 
## # Locate and load the Corpus.
## 
## cname <- file.path(".", "corpus", "txt")
## docs <- Corpus(DirSource(cname))
## 
## docs
## summary(docs)
## inspect(docs[1])
## 
## # Transforms
## 
## toSpace <- content_transformer(function(x, pattern) gsub(pattern, " ", x))
## docs <- tm_map(docs, toSpace, "/|@|\\|")
## 
## docs <- tm_map(docs, content_transformer(tolower))
## docs <- tm_map(docs, removeNumbers)
## docs <- tm_map(docs, removePunctuation)
## docs <- tm_map(docs, removeWords, stopwords("english"))
## docs <- tm_map(docs, removeWords, c("own", "stop", "words"))
## docs <- tm_map(docs, stripWhitespace)
## 
## toString <- content_transformer(function(x, from, to) gsub(from, to, x))
## docs <- tm_map(docs, toString, "specific transform", "ST")
## docs <- tm_map(docs, toString, "other specific transform", "OST")
## 
## docs <- tm_map(docs, stemDocument)
## 
#```
# REVISÃO - ANALISANDO O CORPUS
#```{r}
## ----review_analyse_corpus, eval=FALSE-----------------------------------
## # Document term matrix.
## 
## dtm <- DocumentTermMatrix(docs)
## inspect(dtm[1:5, 1000:1005])
## 
## # Explore the corpus.
## 
## findFreqTerms(dtm, lowfreq=100)
## findAssocs(dtm, "data", corlimit=0.6)
## 
## freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)
## wf   <- data.frame(word=names(freq), freq=freq)
## 
## library(ggplot2)
## 
## p <- ggplot(subset(wf, freq>500), aes(word, freq))
## p <- p + geom_bar(stat="identity")
## p <- p + theme(axis.text.x=element_text(angle=45, hjust=1))
## 
## # Generate a word cloud
## 
## library(wordcloud)
## wordcloud(names(freq), freq, min.freq=100, colors=brewer.pal(6, "Dark2"))
#```
# Informação sobre a Sessão
#```{r}
devtools::session_info()
#```



## FIM 
## UFRN - Minicurso de Mineração de Dados
## Prof. Dr. Belmiro N. João PUC/SP
## baseado (e atualizado) de Hands-On Data Science with R by Graham Williams 
