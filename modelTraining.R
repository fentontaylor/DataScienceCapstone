################################################################################
# Download data files
################################################################################

fileURL <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
if(!file.exists(basename(fileURL))){
    download.file(fileURL, basename(fileURL))
    unzip(basename(fileURL))
}

blog <- readLines(con = "./final/en_US/en_US.blogs.txt", encoding= "UTF-8", skipNul = T)
news <- readLines(con = "./final/en_US/en_US.news.txt", encoding= "UTF-8", skipNul = T)
twit <- readLines(con = "./final/en_US/en_US.twitter.txt", encoding= "UTF-8", skipNul = T)

################################################################################
# Split the files into training, dev, and test sets
################################################################################

# Randomly permute the order of lines in the files for splitting
set.seed(310)
blog <- blog[sample(seq(length(blog)))]
news <- news[sample(seq(length(news)))]
twit <- twit[sample(seq(length(twit)))]

# Split the blog text
n <- length(blog)
train.blog <- blog[1:floor(n*0.6)]
dev.blog <- blog[(floor(n*0.6)+1):floor(n*0.8)]
test.blog <- blog[(floor(n*0.8)+1):n]
# Split the news text
n <- length(news)
train.news <- news[1:floor(n*0.6)]
dev.news <- news[(floor(n*0.6)+1):floor(n*0.8)]
test.news <- news[(floor(n*0.8)+1):n]
# Split the twitter text
n <- length(twit)
train.twit <- twit[1:floor(n*0.6)]
dev.twit <- twit[(floor(n*0.6)+1):floor(n*0.8)]
test.twit <- twit[(floor(n*0.8)+1):n]

################################################################################
# Write files for later use
################################################################################

if(!dir.exists("data")) {dir.create("data")}
if(!dir.exists("data/small")) {dir.create("data/small")}
if(!dir.exists("data/train")) {dir.create("data/train")}
if(!dir.exists("data/test")) {dir.create("data/test")}
if(!dir.exists("data/dev")) {dir.create("data/dev")}
write(train.blog, "data/train/train.blog.txt")
write(train.news, "data/train/train.news.txt")
write(train.twit, "data/train/train.twit.txt")
write(small.blog, "data/small/small.blog.txt")
write(small.news, "data/small/small.news.txt")
write(small.twit, "data/small/small.twit.txt")
write(dev.blog, "data/dev/dev.blog.txt")
write(dev.news, "data/dev/dev.news.txt")
write(dev.twit, "data/dev/dev.twit.txt")
write(test.blog, "data/test/test.blog.txt")
write(test.news, "data/test/test.news.txt")
write(test.twit, "data/test/test.twit.txt")
rm(list = ls())

################################################################################
# Model Training 
################################################################################
require(tm)
require(stringi)
require(filehash)
library(quanteda)
library(data.table)
if(!dir.exists("data/train/train")) dir.create("data/train/train")
if(!dir.exists("data/train/holdout")) dir.create("data/train/holdout")
source("functions.R")

################################################################################
# Split into training and holdout data for later use.
################################################################################

for(i in grep("txt$", dir("data/train"), value = T)){
    temp <- readLines(paste0("data/train/",i))
    n <- length(temp)
    m <- floor(n*0.5)
    tempt <- temp[1:m]
    filename <- paste0("data/train/train/",i)
    if(!file.exists(filename)) write(tempt, filename)
    temph <- temp[m+1:n]
    filename <- paste0("data/train/holdout/", sub("([^.]*)\\.","holdout.",i))
    if(!file.exists(filename)) write(temph, filename)
    rm(temp, n, m, tempt, temph, filename)
}

################################################################################
# Run cleanPCorpus() custom function to process the text for analysis
################################################################################
fileURL <- "http://www.freewebheaders.com/wordpress/wp-content/uploads/full-list-of-bad-words-banned-by-google-txt-file.zip"
download.file(fileURL, "data/profanityWords.zip")
unzip("data/profanityWords.zip", exdir = "data")
file.rename(file.path("data", grep("full-list", dir("data"), val=T)), "data/profanityWords.txt")

cleanPCorpus("data/train/train")
cleanPCorpus("data/train/holdout")
cleanPCorpus("data/dev")
cleanPCorpus("data/test")


################################################################################
# Create n-gram/frequency tables for unigrams, bigrams, and trigrams 
# (anything bigger can't be processed all at once due to RAM limitations)
################################################################################

# create_ngrams() is a custom function and can be found in the functions.R file
create_ngrams("data/train/train/clean", "model_1", c("uni","bi","tri"))
create_ngrams("data/train/holdout/clean", "model_1", c("uni","bi","tri"))

################################################################################
# Split large training and holdout sets for processing 4-5-6-grams.
################################################################################

dir.create("data/trainSplit")
dir.create("data/trainSplit/train")
dir.create("data/trainSplit/holdout")
files <- dir("data/train/train/clean")
file.copy(from=file.path("data/train/train/clean",files), 
          to=file.path("data/trainSplit/train",files))
files <- dir("data/train/holdout/clean")
file.copy(from=file.path("data/train/holdout/clean",files), 
          to=file.path("data/trainSplit/holdout",files))

dir1 <- "data/trainSplit/train"
files1 <- dir(dir1)
file.rename(from = file.path(dir1, files1),
            to = file.path(dir1, gsub("clean_train", "t", files1)))

dir2 <- "data/trainSplit/holdout"
files2 <- dir(dir2)
file.rename(from = file.path(dir2, files2),
            to = file.path(dir2, gsub("clean_holdout", "h", files2)))

files1 <- dir(dir1)
files2 <- dir(dir2)

splitText(dir1, files1, 8) # Custom function to split text into smaller chunks
splitText(dir2, files2, 8)

for( i in 1:8 ){
    DIR <- file.path(dir1, i)
    create_ngrams(DIR, modelName = paste0("mod_part_",i), 
                  type = c("quad", "five", "six"), saveAll = TRUE)
}
for( i in 1:8 ){
    DIR <- file.path(dir2, i)
    create_ngrams(DIR, modelName = paste0("mod_part_",i), 
                  type = c("quad", "five", "six"), saveAll = TRUE)
}

sampleFile <- "data/trainSplit/train/Z/mod_part_Z/quad_freq_s.rds"
files <- character()
for( i in 1:8 ) { files[i] <- gsub("Z", i, sampleFile) }
combine_tables(files, saveNew = "data/trainSplit/train/combo4.rds")

files <- gsub("quad", "five", files)
combine_tables(files, saveNew = "data/trainSplit/train/combo5.rds")

files <- gsub("five", "six", files)
combine_tables(files, saveNew = "data/trainSplit/train/combo6.rds")
rm(list=ls())

################################################################################
# Create 5% of original training and holdout sets for model testing
################################################################################

dir.create("data/train5")
for(i in grep("txt$", dir("data/train/train"), value = T)){
    temp <- readLines(paste0("data/train/train/",i))
    temp <- temp[sample(seq(length(temp)))]
    n <- length(temp)
    m <- floor(n*0.167)
    temp <- temp[1:m]
    filename <- paste0("data/train5/",i)
    if(!file.exists(filename)) write(temp, filename)
}
dir.create("data/holdout5")
for(i in grep("txt$", dir("data/train/holdout"), value = T)){
    temp <- readLines(paste0("data/train/holdout/",i))
    temp <- temp[sample(seq(length(temp)))]
    n <- length(temp)
    m <- floor(n*0.167)
    temp <- temp[1:m]
    filename <- paste0("data/holdout5/",i)
    if(!file.exists(filename)) write(temp, filename)
}
cleanPCorpus("data/train5")
cleanPCorpus("data/holdout5")

create_ngrams("data/train5/clean", "model_5", 
              c("uni","bi","tri","quad","five","six"))

create_ngrams("data/holdout5/clean", "model_5", 
              c("uni","bi","tri","quad","five","six"))

################################################################################
# Perform Simple Good-Turing Smoothing
################################################################################

dir1 <- "data/train/train/clean/model_1"
dir2 <- "data/trainSplit/train"
files <- c(file.path(dir1, "uni_freq.rds"),
           file.path(dir1, "bi_freq_s.rds"),
           file.path(dir1, "tri_freq_s.rds"),
           file.path(dir2, "combo4.rds"),
           file.path(dir2, "combo5.rds"),
           file.path(dir2, "combo6.rds"))
saveDir <- "data/train/train/clean/smooth"
if( !dir.exists(saveDir) ) dir.create(saveDir)

for(i in seq(files)){ 
    df <- readRDS(files[i])
    df <- sgt_smooth(df, 5)
    saveRDS(df, file.path(saveDir,paste0(i, "-gram_smooth.rds")))
}
rm(dir1,dir2)

################################################################################
# Create list of 1 to 6-grams with smoothed counts for prediction algorithm
################################################################################

saveDir <- "data/train/train/clean/smooth"
files <- file.path(saveDir,dir(saveDir))
ngram_list <- function(files, trim=NULL, save=NULL){
    nl <- list()
    
    nl[["bi"]] <- readRDS(files[2])
    if( !is.null(trim) ) nl$bi <- nl$bi[nl$bi$freq > trim, ]
    
    nl[["tri"]] <- readRDS(files[3])
    if( !is.null(trim) ) nl$tri <- nl$tri[nl$tri$freq > trim, ]
    
    nl[["quad"]] <- readRDS(files[4])
    if( !is.null(trim) ) nl$quad <- nl$quad[nl$quad$freq > trim, ]
    
    nl[["five"]] <- readRDS(files[5])
    if( !is.null(trim) ) nl$five <- nl$five[nl$five$freq > trim, ]
    
    nl[["six"]] <- readRDS(files[6])
    if( !is.null(trim) ) nl$six <- nl$six[nl$six$freq > trim, ]
    
    if( !is.null(save) ) { saveRDS(nl, save) }
    
    nl
    
}
system.time(ngrams <- ngram_list(files, trim=1, save=file.path(saveDir,"ngrams_smooth_trim1.rds")))
rm(ngrams)
system.time(ngrams <- ngram_list(files, trim=5, save=file.path(saveDir,"ngrams_smooth_trim5.rds")))
rm(list=ls())

################################################################################
# Create short list of top 25 n-grams for app
################################################################################
saveDir <- "data/train/train/clean/smooth"
files <- file.path(saveDir, dir(saveDir))
shortList <- list()
makeShortList <- function(x){
    df <- readRDS(x)
    df <- df[1:25,]
    df$r_smooth <- round(df$r_smooth, 1)
    df$pr <- round(df$pr, 5)
    df
}
# For some reason, attempts to use lapply and for-loop failed, so I had to resort
# to copy and pasting.
shortList[[1]] <- makeShortList(files[1])
shortList[[2]] <- makeShortList(files[2])
shortList[[3]] <- makeShortList(files[3])
shortList[[4]] <- makeShortList(files[4])
shortList[[5]] <- makeShortList(files[5])
shortList[[6]] <- makeShortList(files[6])

saveRDS(shortList, file.path(saveDir, "shortList.rds"))
file.copy(file.path(saveDir, "shortList.rds"), "textPredictor/data/shortList.rds", overwrite = TRUE)
rm(list=ls())

################################################################################
# Create small samples for app
################################################################################
b <- readLines("data/train/train/train.blog.txt")
b <- sample(b, 200)
b <- b[(nchar(b)>50 & nchar(b) <300)]
b <- sample(b, 20)

n <- readLines("data/train/train/train.news.txt")
n <- sample(n, 200)
n <- n[(nchar(n)>50 & nchar(n)<300)]
n <- sample(n, 20)

t <- readLines("data/train/train/train.twit.txt")
t <- sample(t, 20)

sampleDir <- "data/train/train/samples"
if( ! dir.exists(sampleDir) ) dir.create(sampleDir)
write(b, file.path(sampleDir, "sample.blog.txt"))
write(n, file.path(sampleDir, "sample.news.txt"))
write(t, file.path(sampleDir, "sample.twit.txt"))

sampleText <- data.frame(text = c(b, n, t), source = rep(c("blog", "news", "twitter"), each =20))
sampleText$text <- as.character(sampleText$text)
saveRDS(sampleText, "data/train/train/samples/sampleText.rds")
file.copy("data/train/train/samples/sampleText.rds", "textPredictor/data/sampleText.rds")
rm(list=ls())