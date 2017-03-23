library(shiny)
library(shinydashboard)

ui <- dashboardPage(
    dashboardHeader(title="Next Word Prediction"),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Prediction", tabName = "algorithm", icon = icon("sliders")),
            menuItem("The Data", tabName = "data", icon = icon("bar-chart")),
            menuItem("Additional Info", tabName = "doc", icon = icon("question-circle"))
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(
                tabName = "algorithm",
                h2(strong("Word Prediction Algorithm Application")),
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
                            The prediction algorithm will search up to the last 5 words
                            input and return the most probable word(s) according to the desired 
                            parameters, which can be selected in the "Paramters" box.</p>
                            <b>Parameters</b><br>
                            <ul>
                            <li><b>Which do you prefer?</b> Choose if you want the
                            algorithm to search a larger (<em>Accuracy</em>) or smaller (<em>Speed</em>) database.</li>
                            <li><b>Max number of predictions:</b> If the algorithm returns multiple
                            search results, how many do you want to display? If there are fewer results
                            than your desired maximum, then only those results will be displayed.</li>
                            <li><b>Show prediction details:</b> If checked, will display the final string 
                            used to generate the prediction results and the total number of results returned.</li>
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
                tabsetPanel(
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">Documentation</span>'),
                        HTML("<br>
                             <ul>
                             <li>If you are curious about the nitty-gritty details of what is going on under the hood, this page will hopefully answer any questions you have.</li> 
                             <li>To get a feel for exactly what the cleaning function does, you can go to The Data section to view samples of pre/post-processed text.</li>
                             <li>If you want to see the actual source code for this app and the entire project, click on the link to my GitHub repository for the project in the Source Code tab.</li>
                             <br>
                             <b>Cleaning the Input Text</b>
                             <p>The input text is cleaned with the essentially the same function used to clean the texts in the training corpus. Those steps inlcude:</p>
                             <ol>
                             <li>Convert characters to ASCII.</li>
                             <li>Convert to lower case.</li>
                             <li>Remove profanity words using Google's bad word list.</li>
                             <li>Replace all foreign unicode character codes with a space.</li>
                             <li>Delete all twitter-style hashtag references.</li>
                             <li>Delete website names.</li>
                             <li>Replace all punctuation except EOS punctuation and apostrophe with a space.</li>
                             <li>Delete all numbers.</li>
                             <li>Replace all instances of multiple EOS punctuation with one instance.</li>
                             <li>Replace . ? ! with EOS tag.</li>
                             <li>Remove any extra ? ! .</li>
                             <li>Convert very common occurence of u.s to US.</li>
                             <li>Remove single letters except for 'a' and 'i'.</li>
                             <li>Clean up leftover punctuation artifacts.</li>
                             <li>Strip excess white-space.</li>
                             <li>Remove all text before EOS puntuation.</li>
                             <li>Remove any white-space at the end of the string.</li>
                             <br>
                             </ol>
                             <b>How the Algorithm Works</b>
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
                             <li>Return the top word(s) according to the user's desired maximum.</li>
                             </ol>")),
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">About</span>')),
                    tabPanel(title=HTML('<span style="font-weight:bold; font-size:18px; color:#1E77AB">Source Code</span>'))
                )
            )
        )
    )
)