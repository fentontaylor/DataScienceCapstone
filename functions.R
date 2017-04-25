downloadTextDataset <- function(){
    fileURL <- "https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip"
    if(!file.exists(basename(fileURL))){
        download.file(fileURL, basename(fileURL))
        unzip(basename(fileURL))
    }
}

subsetTextLines <- function(x, percent, destfile=NULL, encoding="UTF-8", seed, save=TRUE){
    if( percent<=0 | percent>=1) stop("percent must be be a value between 0 and 1")
    if(save==TRUE & is.null(destfile)) stop("must specify destfile if save=TRUE")
    set.seed(seed)
    con <- file(x)
    txt <- readLines(con, encoding=encoding, skipNul = TRUE)
    close(con)
    n <- length(txt)
    subtxt <- txt[sample(1:n,n*percent)]
    if(save==FALSE) return(subtxt)
    if(save==TRUE) write.table(subtxt, file=destfile, quote=FALSE, sep = "\n", 
                               row.names=FALSE, col.names=FALSE, 
                               fileEncoding = encoding)
}

nWords <- function(x) {
    suppressMessages(require(stringr))
    str_count(x, "\\S+") %>%
        sum
}

myChars <- function(x, n=seq(x)) {
    # x: a Corpus
    # n: the elements of x for which characters will be returned
    require(stringr)
    t <- character()
    for(i in n){
        t <- c(t, x[[i]][[1]])
    }
    t %>%
    str_split("") %>%
    sapply(function(x) x[-1]) %>%
    unlist %>%
    unique %>%
    sort(dec=T)
}

cleanPCorpus <- function(x) { 
    # x: a path to a directory containing the raw txt files for the Corpus
    suppressMessages(library(tm))
    suppressMessages(library(filehash))
    
    files <- dir(x)
    dbDir <- file.path(x, "db")
    if(!dir.exists(dbDir)) (dir.create(dbDir))
    cleanDir <- file.path(x,"clean")
    if(!dir.exists(cleanDir)) (dir.create(cleanDir))
    dbFile <- file.path(x,"db", paste0(basename(x),".db"))
    if(!file.exists(dbFile)){
    corp <- PCorpus(DirSource(x), dbControl=list(dbName=dbFile, dbType="DB1"))
    }
    print("CONVERTING CHARACTERS...")
    dat <- sapply(corp, function(row) iconv(row, "latin1", "ASCII", sub=""))
    print("CREATING TEMP FILES...")
    tempDir <- file.path(x,"temp")
    if(!dir.exists(tempDir)) dir.create(tempDir)
    for(i in seq(files)){
        write(dat[[i]], file.path(tempDir, files[i]))
    }
    rm(dat)
    dbCleanFile <- file.path(x,"db",paste0(basename(x),"Clean.db"))
    corp <- PCorpus(DirSource(tempDir), 
                    dbControl=list(dbName=dbCleanFile,
                                   dbType="DB1"))
    print("BEGINNING TRANSFORMATIONS...")
    swap <- content_transformer(function(x, from, to) gsub(from, to, x))
    corp <- tm_map(corp, content_transformer(tolower))
    # Remove profanity words
    profanityWords <- readLines(con="data/profanityWords.txt", skipNul = T)
    corp <- tm_map(corp, removeWords, profanityWords)
    print("PROFANITY REMOVAL COMPLETE...")
    # Replace all foreign unicode character codes with a space
    corp <- tm_map(corp, swap, "<.*>", " ")
    # Delete all twitter-style hashtag references
    corp <- tm_map(corp, swap, "#[a-z]+", " ")
    # Delete website names
    corp <- tm_map(corp, swap, "[[:alnum:][:punct:]]+\\.(?:com|org|net|gov|co\\.uk|aws|fr|de)([\\/[:alnum:][:punct:]]+)?", "webURL")
    # Replace all punctuation except EOS punctuation and apostrophe with a space
    print("WEB-BASED TEXT REMOVAL COMPLETE...")
    corp <- tm_map(corp, swap, "[^[:alnum:][:space:]\'\\.\\?!]", " ")
    # Convert numbers with decimal places to <NUM> marker
    corp <- tm_map(corp, swap, "[0-9]+\\.[0-9]+", "<NUM>")
    # Convert all other numbers to <NUM> marker
    corp <- tm_map(corp, swap, "[0-9]+(\\w*)?", "<NUM>")
    # Replace all instances of multiple EOS punctuation with one instance
    corp <- tm_map(corp, swap, "([\\.\\?!]){2,}", ". ")
    # Replace . ? ! with <EOS> tag
    corp <- tm_map(corp, swap, "\\. |\\.$", " <EOS> ")
    corp <- tm_map(corp, swap, "\\? |\\?$|\\b\\?\\b", " <EOS> ")
    corp <- tm_map(corp, swap, "! |!$|\\b!\\b", " <EOS> ")
    print("<EOS> AND <NUM> TAGGING COMPLETE...")
    # Remove any extra ? !
    corp <- tm_map(corp, swap, "!", " ")
    corp <- tm_map(corp, swap, "\\?", " ")
    # Convert very common occurence of u.s to US
    corp <- tm_map(corp, swap, "u\\.s", "US")
    corp <- tm_map(corp, swap, "\\.", "")
    # Remove single letters except for "a" and "i"
    corp <- tm_map(corp, swap, " [b-hj-z] ", " ")
    # Clean up leftover punctuation artifacts
    corp <- tm_map(corp, swap, " 's", " ")
    corp <- tm_map(corp, swap, " ' ", " ")
    corp <- tm_map(corp, swap, "\\\\", " ")
    
    corp <- tm_map(corp, stripWhitespace)
    print("ALL TRANSFORMATIONS COMPLETE")
    print("WRITING CORPUS TEXT TO DISK...")
    writeCorpus(corp, cleanDir, filenames = paste0("clean_",files))
    print("PROCESSING SUCCESSFULLY FINISHED")
}

cleanTextFull <- function(x) {
    require(tm)
    require(stringi)
    x <-  iconv(x, "latin1", "ASCII", sub="")
    x <- VCorpus(VectorSource(x))
    swap <- content_transformer(function(x, from, to) gsub(from, to, x))
    x <- tm_map(x, content_transformer(tolower))
    profanityWords <- readLines(con="data/profanityWords.txt", skipNul = T)
    x <- tm_map(x, removeWords, profanityWords)
    x <- tm_map(x, swap, "<.*>", " ")
    x <- tm_map(x, swap, "#[a-z]+", " ")
    x <- tm_map(x, swap, "[[:alnum:][:punct:]]+\\.(?:com|org|net|gov|co\\.uk|aws|fr|de)([\\/[:alnum:][:punct:]]+)?", "webURL")
    x <- tm_map(x, swap, "[^[:alnum:][:space:]\'\\.\\?!]", " ")
    x <- tm_map(x, swap, "[0-9]+\\.[0-9]+", "")
    x <- tm_map(x, swap, "[0-9]+(\\w*)?", "")
    x <- tm_map(x, swap, "([\\.\\?!]){2,}", ". ")
    x <- tm_map(x, swap, "\\. |\\.$", " <EOS> ")
    x <- tm_map(x, swap, "\\? |\\?$|\\b\\?\\b", " <EOS> ")
    x <- tm_map(x, swap, "! |!$|\\b!\\b", " <EOS> ")
    x <- tm_map(x, swap, "!", " ")
    x <- tm_map(x, swap, "\\?", " ")
    x <- tm_map(x, swap, "u\\.s", "US")
    x <- tm_map(x, swap, "\\.", "")
    x <- tm_map(x, swap, " [b-hj-z] ", " ")
    x <- tm_map(x, swap, " 's", " ")
    x <- tm_map(x, swap, " ' ", " ")
    x <- tm_map(x, swap, "\\\\", " ")
    x <- tm_map(x, stripWhitespace)
    x[[1]]$content
}

cleanTextQuick <- function(x) {
    suppressMessages(require(stringi))
    x <- tolower(x)
    x <- stri_replace_all_regex(x, "[[:alnum:][:punct:]]+\\.(?:com|org|net|gov|co\\.uk|aws|fr|de)([\\/[:alnum:][:punct:]]+)?", "webURL")
    x <- stri_replace_all_regex(x, "[^[:alnum:][:space:]\'\\.\\?!]", "")
    x <- stri_replace_all_regex(x, "[0-9]+\\.[0-9]+", "")
    x <- stri_replace_all_regex(x, "[0-9]+(\\w*)?", "")
    x <- stri_replace_all_regex(x, "([\\.\\?!]){2,}", ". ")
    x <- stri_replace_all_regex(x, "\\. |\\.$", " <EOS> ")
    x <- stri_replace_all_regex(x, "\\? |\\?$|\\b\\?\\b", " <EOS> ")
    x <- stri_replace_all_regex(x, "! |!$|\\b!\\b", " <EOS> ")
    x <- stri_replace_all_regex(x, "[ ]{2,}", " ")
}

n_toks <- function(toks, ng, name, saveDir, saveAll){
    # helper function for create_ngrams
    # toks: quanteda tokens object of unigrams
    # saveAll: should all the intermediary files be saved? (tokens, dfm, word/freq)
    #           if FALSE, only the word/freq data.frame is saved
    if(ng != 1) {
        toks <- tokens_ngrams(toks, n=ng, concatenator=" ")
    }
    if(saveAll) {saveRDS(toks, paste0(saveDir,"/",name,"_toks.rds"))}
    dfm <- dfm(toks, tolower=FALSE)
    if(saveAll) {saveRDS(dfm, paste0(saveDir,"/",name,"_dfm.rds"))}
    n_freq <- freq_df(dfm)
    rm(dfm)
    if(saveAll) {saveRDS(n_freq, paste0(saveDir,"/",name,"_freq.rds"))}
    n_freq <- n_freq[-grep("EOS|NUM", n_freq$words),]
    saveRDS(n_freq, paste0(saveDir,"/",name,"_freq_s.rds"))
    rm(n_freq)
}

create_ngrams <- function(x, modelName, type, saveAll=TRUE) {
    # x: directory containing clean text files
    # modelName: sub-directory of x to save ngram files
    # type: character vector specifying which ngrams to create 
    #       options are c("uni","bi","tri","quad","five","six")
    # saveAll: should all the intermediary files be saved? (tokens, dfm, word/freq)
    #           if FALSE, only the word/freq data.frame is saved
    suppressMessages(require(tm))
    suppressMessages(require(quanteda))
    
    print("Creating Corpus...")
    myCorp <- VCorpus(DirSource(x))
    myCorp <- corpus(myCorp)
    
    
    mod_dir <- file.path( x, modelName )
    if( !dir.exists( mod_dir ) ) dir.create( mod_dir )
    
    print("Creating Tokens...")
    toks <- tokens(myCorp, removeSymbols=TRUE)
    
    if("uni" %in% type){
        print("Creating Unigrams...")
        n_toks(toks=toks, ng=1, name="uni", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
    
    if("bi" %in% type){ 
        print("Creating Bigrams...")
        n_toks(toks=toks, ng=2, name="bi", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
    
    if("tri" %in% type){
        print("Creating Trigrams...")
        n_toks(toks=toks, ng=3, name="tri", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
    
    if("quad" %in% type){
        print("Creating Quadgrams...")
        n_toks(toks=toks, ng=4, name="quad", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
    
    if("five" %in% type){
        print("Creating Fivegrams...")
        n_toks(toks=toks, ng=5, name="five", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
    
    if("six" %in% type){
        print("Creating Sixgrams...")
        n_toks(toks=toks, ng=6, name="six", saveDir=mod_dir, saveAll=saveAll)
        print("Complete")
    }
}

combine_tables <- function(files, saveNew=NULL){
    # files: character vector of files to be combined
    # saveNew: character vector of file.path to save output table
    suppressMessages(require(dplyr))
    suppressMessages(require(data.table))
    out <- data.frame(words=character(),freq=numeric())
    for( i in seq_along(files) ){
        temp <- as.data.table(readRDS(files[i]))
        out <- full_join(out, temp, by="words")
    }
    out <- out %>% 
        mutate(freq=rowSums(.[,-1],na.rm=TRUE)) %>% 
        select(c(words,freq)) %>% 
        arrange(desc(freq)) %>%
        as.data.table()
    if( !is.null(saveNew) ) { saveRDS(out, saveNew) }
}

freq_df <- function(x){
    suppressMessages(require(data.table))
    # This helper function takes a token output and outputs a sorted N-gram frequency table
    fr <- sort(colSums(as.matrix(x)),decreasing = TRUE)
    df <- data.table(words = as.character(names(fr)), freq=fr)
    return(df)
}

freqMat <- function(df){
    suppressMessages(require(dplyr))
    mat <- df %>% group_by(freq) %>% summarise(n())
    colnames(mat) <- c("r", "Nr")
    return(mat)
}

makeZr <- function(df){
    # Step 1 in simple Good-Turing Smoothing
    # df: a frequency of frequency data frame, like the output of freq_df()
    #     with counts in the first column and frequency of counts in the second.
    suppressMessages(require(dplyr))
    if(names(df)[1]!="r" | names(df)[2]!="Nr") names(df) <- c("r","Nr")

    Zr <- numeric()
    m <- nrow(df)
    for(i in seq(m)){
        q <- ifelse(i==1, 0, df[[i-1,1]])
        t <- ifelse(i==m, 2*df[[i,1]]-q, df[[i+1,1]])
        Zr[i] <- df[[i,2]]/(0.5*(t-q))
    }
    df$Zr <- Zr
    return(df)
}

do_lgt_r <- function(df) {
    # Step 2 performs linear Good-Turing smoothing
    # df: a data.frame output from the makeZr() function
    
    logr <- log10(df$r)
    logzr <- log10(df$Zr)
    fit <- lm(logzr~logr)
    b <- coef(fit)[2]
    if(b>-1) stop("Slope of regression line is greater than -1")
    df$lgt_r <- df$r*(1+1/df$r)^(b+1)
    return(df)
}

do_gt_r <- function(df, threshold){
    # Step 3 perform regular Good-Turing Smoothing
    # df: a data.frame ouput from do_lgt_r()
    # threshold: the value of r (count) to perform simple Good-Turing estimates up to
    gt_r <- numeric()
    for( i in seq(threshold) ){
        r <- df[[i,1]]
        N <- df[[i+1,2]]/df[[i,2]]
        gt_r[i] <- (r+1)*N
    }
    gt_r <- c(gt_r,rep(NA, nrow(df)-length(gt_r)))
    df$gt_r <- gt_r
    return(df)
}

sgt_smooth <- function(df, threshold){
    # wrapper function for all components of simple Good-Turing smoothing
    suppressMessages(require(dplyr))
    fm <- df %>% 
        freqMat() %>% 
        makeZr() %>% 
        do_lgt_r() %>%
        do_gt_r(threshold=threshold)
    fm$sgt <- c(fm$gt_r[1:threshold], fm$lgt_r[(threshold+1):nrow(fm)])
    
    df$r_smooth <- rev(rep(fm$sgt,fm$Nr))
    N <- sum(fm$r*fm$Nr)
    df$pr <- df$r_smooth/N
    tot <- sum(df$pr)
    df$pr <- df$pr/tot
    
    df
}

splitText <- function(directory, files, chunkSize){
    for( i in files ){
        num <- length(readLines(file.path(directory, i)))
        chunk <- ceiling(num/chunkSize)
        con <- file(file.path(directory, i), open = "r")
        
        for( j in 1:8 ){
            if( !dir.exists( file.path(directory, j) ) ){
                dir.create( file.path(directory, j) )
            }
            lines <- readLines(con, n=chunk)
            writeLines(lines, file.path(directory, j, paste0(j,".",i)))
        }
        close(con)
    }
}
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

nextWord <- function(x, ngrams, num=1) {
    # x: a character string
    # ngrams: list of n-grams
    # n: number of words to return
    
    require(stringi)
    require(dplyr)
    # Clean the text with the same process that generated n-gram lists
    x <- cleanTextQuick(x)
    # Delete text before EOS punctuation since it will skew prediction.
    x <- gsub(".*<EOS>", "", x)
    x <- gsub(" $", "", x)
    # Get length of string for loop iterations
    m <- length(stri_split_fixed(str=x, pattern=" ")[[1]])
    m <- ifelse(m < 5, m, 5)
    
    for( i in m:1 ){
        x <- stri_split_fixed(str=x, pattern=" ")[[1]]
        n <- length(x)
        # As i decreases, length of x is shortened to search smaller n-grams
        x <- paste(x[(n-i+1):n], collapse=" ")
        search <- grep(paste0("^", x, " "), ngrams[[i]]$words)
        
        if( length(search) == 0 ) { next }
        break
    }
    
    choices <- ngrams[[i]][search,]
    choices <- arrange(choices, desc(freq))
    words <- gsub(paste0(x," "), "", choices$words)
    if (length(words)==0) { words <- c("the", "to", "and", "a", "of") }
    words[1:num]
}

trimString <- function(x, n) {
    suppressMessages(require(stringi))
    temp <- stri_split_fixed(x, " ", simplify = T)
    paste(temp[1:n], collapse = " ")
}

getLastWord <- function(x){
    suppressMessages(require(stringi))
    temp <- stri_split_fixed(x, " ", simplify = T)
    n <- length(temp)
    temp[n]
}

pruneNgrams <- function(x, n, save = NULL) {
    # x : ngram list
    # n : number of each group to keep
    #save : file.path to save pruned ngram list
    
    suppressMessages(require(data.table))
    x <- data.table(x)
    x <- x[ , group := sapply(words, function(z) trimString(z, n))]
    x <- setorder(setDT(x), group, -pr)[, index := seq_len(.N), group][index <= 5L]
    x <- x[, c("group", "index") := NULL]
    if( !is.null(save) ) saveRDS(x, save)
    x
}

nextWord2 <- function(x, ngrams, num=1) {
    # x: a character string
    # ngrams: list of n-grams
    # num: number of words to return
    
    require(stringi)
    require(dplyr)
    # Clean the text with the same process that generated n-gram lists
    x <- cleanTextQuick(x)
    # Delete text before EOS punctuation since it will skew prediction.
    x <- gsub(".*<EOS>", "", x)
    x <- gsub(" $", "", x)
    # Get length of string for loop iterations
    m <- length(stri_split_fixed(str=x, pattern=" ")[[1]])
    m <- ifelse(m < 5, m, 5)
    
    for( i in m:1 ){
        x <- stri_split_fixed(str=x, pattern=" ")[[1]]
        n <- length(x)
        # As i decreases, length of x is shortened to search smaller n-grams
        x <- paste(x[(n-i+1):n], collapse=" ")
        search <- grep(paste0("^", x, " "), ngrams[[i]]$words)
        
        if( length(search) == 0 ) { next }
        break
    }
    
    choices <- ngrams[[i]][search,]
    choices <- arrange(choices, desc(freq))
    words <- gsub(paste0(x," "), "", choices$words)
    if (length(words)==0) { ng_ret = 1 }
    else{ ng_ret = i+1 }
    ng_ret
}