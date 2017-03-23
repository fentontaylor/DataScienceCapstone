library(shiny)
library(shinydashboard)
library(stringi)
library(dplyr)
library(ggplot2)
suppressMessages(library(tm))

# Load n-gram tables and data exploration files
ngrams_accuracy <- readRDS("data/ngrams_smooth_trim1.rds")
ngrams_speed <- readRDS("data/ngrams_smooth_trim5.rds")
shortList <- readRDS("data/shortList.rds")
sampleText <- readRDS("data/sampleText.rds")

cleanText <- function(x) {
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

shinyServer(function(input, output) {
  
    ngrams <- reactive({
        if(input$preference=="Accuracy") { ngrams_accuracy }
        else { ngrams_speed }
    }) 
    
    predList <- reactive({
        # Clean the text with the same process that generated n-gram lists
        x <- input$text
        x <- cleanText(x)
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
            search <- grep(paste0("^", x, " "), ngrams()[[i]]$words)
            
            if( length(search) == 0 ) { next }
            break
        }
        
        choices <- ngrams()[[i]][search,]
        choices <- arrange(choices, desc(freq))
        words <- gsub(paste0(x," "), "", choices$words)
        list(x=x, choices=choices, words=words)
    })

    output$prediction <- renderText({
        words <- predList()$words
        n <- length(words)
        max <- input$maxResults
        if ( n == 0 ) {
            if( input$text == "" ) { 
                print("Please begin typing...")
            } else if (input$text != "" & predList()$x == "") {
                print("Please continue typing...")
            } else {
                paste(shortList[[1]]$words[1:max], collapse = " | ")
            }
        } else if ( n > max ) { 
            paste(words[1:max], collapse = " | ")
        } else { 
            paste(words, collapse = " | ")
        }
    })
    
    output$details <- renderUI({
        if(input$showDetails) {
            HTML('<p><b>Prediction String: </b>"', predList()$x, '"</p>
                  <p><b>Results Returned: </b>', length(predList()$words),'</p>')  
        } else NULL
    })
  
    output$ngram_plot <- renderPlot({
          selection1 <- which(c("1-grams", "2-grams", "3-grams","4-grams", "5-grams", "6-grams")==input$ngram)
          selection2 <- which(c("Raw Count", "Smoothed Count", 
                                "Smoothed Probability")==input$plotBy)+1
          df <- shortList[[selection1]]
          par(las=2, mar=c(5, 2, 1, 10))  
          bp <- barplot(rev(df[,selection2]), horiz = TRUE, col = "#FF773D",
                  border = NA, space = .4, ylim = c(1,50), width=1.5)
          text(x=rev(df[,selection2]), y=bp, xpd=NA, pos=4, labels = rev(df$words), cex = 1.2)
          text(x=rev(df[,selection2]), y=bp, xpd=NA, pos=2, labels = rev(df[,selection2]), 
               cex=0.75, col = "white")
    })
  
    sampleTextIn <- reactive({
        if(!(input$userTextInput=="")){
              input$userTextInput
        } else {
        dat <- sampleText[sampleText$source==tolower(input$sourceSelection),]
        dat <- dat[[input$sampleNumber, "text"]]
        dat }
      })
    
    output$textIn <- renderText({
      print(sampleTextIn())
    })

    output$textOut <- renderText({
        cleanText(sampleTextIn())
    })
})