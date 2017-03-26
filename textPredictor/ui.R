library(shiny)
library(shinydashboard)

ui <- dashboardPage(
    dashboardHeader(title="Next Word Prediction"),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Prediction", tabName = "algorithm", icon = icon("sliders")),
            menuItem("The Data", tabName = "data", icon = icon("bar-chart")),
            menuItem("Additional Info", tabName = "doc", icon = icon("info-circle"))
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(
                tabName = "algorithm",
                h2(strong("Next Word Predictor")),
                p("Please allow a moment for the app to load. It will prompt you to begin typing when it is ready."),
                hr(),
                fluidRow(
                    column(offset=2, width=12, 
                        box( 
                            title = HTML('<span class="fa-stack fa-lg" style="color:#1E77AB">
                                       <i class="fa fa-square fa-stack-2x"></i>
                                       <i class="fa fa-keyboard-o fa-inverse fa-stack-1x"></i>
                                       </span> <span style="font-weight:bold;font-size:24px">
                                       Type in a Phrase</span>'),
                            textInput(inputId="text", label=""),
                            h3(textOutput("prediction")),
                            hr(),
                            uiOutput("details"),
                            width = 8, status = "primary"
                        )
                    )
                ),
                
                fluidRow(
                    box(width = 5, collapsible = TRUE, status = "success",
                        title = HTML('<span class="fa-stack fa-lg" style="color:#2AB27B">
                                  <i class="fa fa-square fa-stack-2x"></i>
                                  <i class="fa fa-cogs fa-inverse fa-stack-1x"></i>
                                  </span> <span style="font-weight:bold;font-size:24px">
                                  Parameters</span>'),
                        selectInput("preference",
                                     "Which do you prefer?",
                                     c("Accuracy","Speed"), 
                                     "Accuracy"),
                        br(),
                        sliderInput("maxResults",
                                     "Max number of predictions to display",
                                     1, 5, 1),
                        checkboxInput("showDetails", "Show Prediction Details", value = TRUE)
                    ),
                    
                    box(width = 7, collapsible = TRUE, status = "warning",
                        title = HTML('<span class="fa-stack fa-lg" style="color:#FF773D">
                                    <i class="fa fa-square fa-stack-2x"></i>
                                    <i class="fa fa-question-circle fa-inverse fa-stack-1x"></i>
                                    </span> <span style="font-weight:bold;font-size:24px">
                                    Instructions</span>'),
                        HTML('<b>Input</b><br>
                            <p style="text-indent: 25px"> Simply type in any phrase you want to the text box above.
                            The prediction algorithm will search up to the last 5 words from the
                            input string and return the most probable word(s) according to the desired 
                            parameters, which can be selected in the "Parameters" box.</p>
                            <b>Parameters</b><br>
                            <ul>
                            <li><b>Which do you prefer?</b> Choose if you want the
                            algorithm to search a larger (<em>Accuracy</em>) or smaller (<em>Speed</em>) database.</li>
                            <li><b>Max number of predictions:</b> If the algorithm returns multiple
                            search results, how many do you want to display? If there are fewer results
                            than your desired maximum, then only those results will be displayed.</li>
                            <li><b>Show prediction details:</b> If checked, will display the final string 
                            used to generate the prediction results.</li>
                            </ul>
                                '),
                        footer = em("For more detailed information, see Documentation under Additional Info.")        
                    )  
                )
            ),
            tabItem(tabName = "data",
                h2(strong("The Data")),
                fluidRow(
                    box(width=7, height = "700px", status = "warning",
                        title = HTML('<span class="fa-stack fa-lg" style="color:#FF773D">
                                    <i class="fa fa-square fa-stack-2x"></i>
                                    <i class="fa fa-bar-chart fa-inverse fa-stack-1x"></i>
                                    </span> <span style="font-weight:bold;font-size:24px">
                                    Frequency of Different Length N-Grams</span>'),
                        splitLayout(
                            selectInput("ngram", "Size of N-gram",
                                choices = c("1-grams", "2-grams", "3-grams", "4-grams", "5-grams", "6-grams"),
                                selected = "1-gram"),
                            selectInput("plotBy", "By which metric?", choices = c("Raw Count",
                                "Smoothed Count", "Smoothed Probability"),
                                selected = "Raw Count (Unsmoothed)"),
                            tags$head(tags$style(HTML(".shiny-split-layout > div {
                                                        overflow: visible; }")))
                        ),
                        plotOutput("ngram_plot", height = "480px")
                    ),
                    box(width=5, height = "700px", status = "success",
                        title = HTML('<span class="fa-stack fa-lg" style="color:#2AB27B">
                                   <i class="fa fa-square fa-stack-2x"></i>
                                   <i class="fa fa-newspaper-o fa-inverse fa-stack-1x"></i>
                                   </span> <span style="font-weight:bold;font-size:24px">
                                   Samples of Pre/Post-Processed Text</span>'),
                        splitLayout(
                            selectInput("sourceSelection", "Source",
                                      choices = c("Blog", "News", "Twitter")),
                            numericInput("sampleNumber", "Sample (1-20)",
                                     value = 1, min = 1, max = 20, step = 1),
                            tags$head(tags$style(HTML(".shiny-split-layout > div {
                                                      overflow: visible; }")))
                        ),
                        br(),
                        textInput("userTextInput", "Or type in your own text:"),
                        HTML('<span style="font-weight:bold;font-size:20px">
                             Original Text:</span><br>'),
                        span(textOutput("textIn"), style = "font-size:16px"),
                        br(),
                        HTML('<span style="font-weight:bold;font-size:20px">
                             Cleaned Text:</span><br>'),
                        span(textOutput("textOut"), style = "font-size:16px")
                    )
                )
            ),
            tabItem(tabName = "doc", 
                tabBox(width = 12,
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">Documentation</span>'),
                        HTML('<br>
                             <ul>
                             <li>If you are curious about the nitty-gritty details of what is going on under the hood, this page will hopefully answer any questions you have.</li> 
                             <li>To get a feel for exactly what the cleaning function does, you can go to The Data section to view samples of pre/post-processed text.</li>
                             <li>If you want to see the actual source code for this app and the entire project, click on the link to my GitHub repository for the project in the Source Code tab.</li>
                             <br>
                             <span style="font-weight:bold;font-size:18px">Cleaning the Input Text</span>
                             <p>The input text is cleaned with the essentially the same function used to clean the texts in the training corpus. Those steps inlcude:</p>
                             <ol>
                             <li>Convert characters to ASCII.</li>
                             <li>Convert to lower case.</li>
                             <li>Remove profanity words using Google\'s bad word list.</li>
                             <li>Replace all foreign unicode character codes with a space.</li>
                             <li>Delete all twitter-style hashtag references.</li>
                             <li>Delete website names.</li>
                             <li>Replace all punctuation except EOS punctuation and apostrophe with a space.</li>
                             <li>Delete all numbers.</li>
                             <li>Replace all instances of multiple EOS punctuation with one instance.</li>
                             <li>Replace . ? ! with EOS tag.</li>
                             <li>Remove any extra ? ! .</li>
                             <li>Convert very common occurence of u.s to US.</li>
                             <li>Remove single letters except for "a" and "i".</li>
                             <li>Clean up leftover punctuation artifacts.</li>
                             <li>Strip excess white-space.</li>
                             <li>Remove all text before EOS puntuation.</li>
                             <li>Remove any white-space at the end of the string.</li>
                             <br>
                             </ol>
                             <span style="font-weight:bold;font-size:18px">How the Algorithm Works</span>
                             <p>The algorithm searches a 6-gram model and uses Stupid Backoff to search lower-order N-grams if the higher-order N-gram does not occur in the model. When searching the 6-gram, the 
                             algorithm searches the last 5 words of the user\'s input phrase in a data frame containing the N-grams and their frequencies/probabilities. If the 5-word phrase occurs in the data frame
                             of 6-grams, the algorithm returns the subset of words that complete the phrase. If the 5-word phrase does not occur in the 6-grams, then Stupid Backoff is performed to search for the 
                             4-word phrase in the 5-grams. If the algorithm backs off completely and finds no occurences of a single word in the 2-grams, then the most common single words are returned. 
                             For example, if the phrase <b>"The chair she sat in, like a burnished"</b> is input, the search string is the last 5 words, <b>"sat in like a burnished"</b>. The search would go as follows:
                             <ul>
                             <li>"sat in like a burnished" : <span style="color:red">0 results</span>
                             <li>"in like a burnished" : <span style="color:red">0 results</span>
                             <li>"like a burnished" : <span style="color:red">0 results</span>
                             <li>"a burnished" : <span style="color:red">0 results</span>
                             <li>"burnished" : <span style="color:green">1 result</span>, <b>"the"</b>
                             </ul><br>
                             <p>Unfortunately, the algorithm got this prediction wrong, as the actual next word of this line from T.S. Eliot\'s <em>The Wasteland</em> is <b>"throne"</b>. Certainly, this line is 
                             fairly uncommon. The prediction algorithm can\'t be expected to give perfect results, but it does a decent job of giving plausible next words most of the time. Below are more details of the algorithm\'s
                             step-by-step process:</p>                             
                             <ol>
                             <li>Get the length (<var>m</var>) of the clean text string (<var>x</var>) and feed it into a for-loop <code>for (i in m:1)</code> where <var>m</var> is controlled to be less than or equal to 5. Each iteration of the for-loop does:</li>
                             <ul>
                             <li>Split <var>x</var> where spaces occur.</li>
                             <li>Get the length (<var>n</var>) of <var>x</var></li>
                             <li>Select a subset of <var>x</var> defined by <code>x[(n-i+1):n]</code>. As the for-loop advances (meaning no instances of the string were found), <var>i</var> decreases, resulting in a lower-order N-gram to be used in the search.</li>
                             <li>Search corresponding N-gram list for occurences of <var>x</var>. For example, if <var>x</var> has length 5, search 6-grams; if length 4, search 5-grams. Save search results.</li>
                             <li>If the search returned zero results, go to the next loop iteration. Otherwise, break out of the loop.</li>
                             </ul>
                             <li>Subset the N-gram list by the search results and arrange them in descending order by frequency.</li>
                             <li>Extract the list of words that complete the search string <var>x</var>.</li>
                             <li>Return the top word(s) according to the user\'s desired maximum.</li>
                             </ol>')),
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">About</span>'),
                             HTML('<br>
                                  <span style="font-weight:bold;font-size:18px">The Assignment</span>
                                  <p style="text-indent: 25px">This application was created for the final assignment of the Johns Hopkins University Data Science Specialization Capstone Project through <a href="https://www.coursera.org/specializations/jhu-data-science"><b>Coursera.org</b></a>.
                                  All natural language processing tasks were done in RStudio using the R packages <a href="https://cran.r-project.org/package=tm"><b>tm</b></a> and <a href="https://cran.r-project.org/package=quanteda"><b>quanteda</b></a>.
                                  Other packages that were utilized were <a href="https://cran.r-project.org/package=dplyr"><b>dplyr</b></a>, <a href="https://cran.r-project.org/package=stringi"><b>stringi</b></a>, 
                                  <a href="https://cran.r-project.org/package=data.table"><b>data.table</b></a>, and <a href="https://cran.r-project.org/package=filehash"><b>filehash</b></a>.</p>
                                  <br>
                                  <span style="font-weight:bold;font-size:18px">The Data</span>
                                  <p style="text-indent: 25px">The texts for this project come from <a href="https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip">this dataset</a>. The data are approximately 4 million lines of
                                  text from blogs, online news publications, and Twitter posts. Incorporating texts from varied sources probably lowers prediction accuracy compared to training a model and predicting for a specific
                                  genre of text. However, using texts from sources with varied styles of writing and vocabulary makes the prediction algorithm more generalizable.</p>
                                  <br>
                                  <span style="font-weight:bold;font-size:18px">Other Details</span>
                                  <p style="text-indent: 25px">The texts were split into 60% training, 20% development, and 20% test sets. The training set was further split equally into training and holdout sets. The holdout
                                  set is necessary for some smoothing techniques and methods for dealing with unseen words. However, for the current prediction algorithm, only simple Good-Turing smoothing was performed on the
                                  counts of the N-grams of lengths 1 to 6. The N-gram lists were "pruned" to only include the top 5 completions for each N-gram, since that is the maximum number of results the algorithm returns 
                                  and it reduces file size and search time.
                                  </p>
                                  <span style="font-weight:bold;font-size:18px">Performance</span>
                                  <p style="text-indent: 25px">Below is the accuracy of the two models. <em>smooth_trim5_prune</em> only includes N-grams that have a raw count of greater than 5. Similarly, <em>smooth_trim1_prune</em> includes only N-grams that occur more than once. The two 
                                  models have fairly similar accuracy, but the smaller model was about 6 times faster. Both perform reasonably well for the purposes of this application, but could certainly be faster.
                                  The bottleneck was identified as the part of the algorithm that searches the N-gram lists. Perhaps lookup tables or a more efficient use of data.tables would improve the speed.</p>'),
                             tableOutput("resultsTable")
                        ),
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">Source Code</span>'),
                             HTML("<br><p style='font-size:16px'>All relevant files for this project and application can be viewed at this 
                                  <a href='https://github.com/fentontaylor/DataScienceCapstone'>GitHub Repository</a>. Thanks for checking it out!</p>"))
                )
            )
        )
    )
)