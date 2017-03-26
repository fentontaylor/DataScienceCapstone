Capstone Project: Word Predicting Application
========================================================
author: Fenton Taylor
date: 23 March, 2017
autosize: true

![img1](coursera-logo2.png) ![img2](jhu-logo.png) ![img3](SwiftKey_logo2.jpg)

The Task
========================================================

This application was created for the final assignment of the Johns Hopkins University Data Science Specialization Capstone Project, which was co-sponsored by SwiftKey. 

The task was to create a model based on texts taken from online blogs, news articles, and Twitter posts ([source](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip))
and use that model in an algorithm to predict the next word in a phrase.

The ultimate goal was to implement the model and prediction algorithm in a Shiny application that takes
user input text and generates a prediction for the next word.


The Model
========================================================
<p style="font-size:24px">
An N-gram (contiguous set of n items from a given sequence of text) model was created from the text sources. The <span style="font-weight:bold;color:steelblue">tm</span> package was used to create a corpus of the texts for necessary pre-processing. Pre-processing included various methods of cleaning and preparing the text, such as converting to ASCII and lower case, profanity and web-text filtering, and end of sentence tagging. For example:</p>


```
[1] Raw Text: John gave her WHAT carat diamond?!?! #crazy
```

```
[1] Clean Text:  john gave her what carat diamond <EOS> 
```

<p style="font-size:24px">
After the corpus was pre-processed. N-grams of lengths 1 to 6 were created using the <span style="font-weight:bold;color:steelblue">quanteda</span> package and the frequency of each N-gram were counted. Finally, <a href="https://en.wikipedia.org/wiki/Good%E2%80%93Turing_frequency_estimation">simple Good-Turing smoothing</a> was performed to adjust for unseen words and N-grams. Example:</p>

```
           words  freq r_smooth      pr
1     one of the 10529  10527.5 0.00084
2       a lot of  8975   8973.5 0.00071
3 thanks for the  7242   7240.5 0.00058
```

The Prediction Function
========================================================

<p style="font-size:28px;font-weight:bold">The prediction algorithm does the following:</p>
<div style="font-size:24px">
<ul>
<li>Takes user text input 
<li>Pre-processes the text to match the format of the cleaned corpus text
<li>Searches the appropriate highest-order N-gram list for the user's text
<li>If no match is found, perform <a href="https://en.wikipedia.org/wiki/Katz%27s_back-off_model">Stupid Backoff</a> until a match is found
<li>Return up to top 5 words that complete the N-gram
<li>If no matches are found, return the top 5 most common words
</ul>
</div>

<p style="font-size:28px;font-weight:bold">Model Performance:</p>


```
     model top_acc top3_acc top5_acc avg_time
1    Speed   0.170    0.250    0.293    0.103
2 Accuracy   0.186    0.258    0.298    0.652
```

The App
========================================================
<p style="font-size:28px">
<a href="https://fentontaylor.shinyapps.io/textPredictor/">The Shiny Application</a>
provides a simple user interface to interact with the prediction algorithm and the data. Notable features include:</p>
<div style = "font-size:24px">
<ul>
<li>Interactive command line to input text for prediction
<li>Parameter selections for the algorithm: model choice, number of results
<li>Interactive plot of most frequent N-grams
<li>Interactive examples of pre/post-processed text
</ul>
</div>
![app3](app3.png) ![app2](app2.png) ![app1](app1.png)

