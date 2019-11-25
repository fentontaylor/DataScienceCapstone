## Welcome

This repository contains all the relevant files for the Johns Hopkins University Data Science Specialization Capstone Project.

- **textPredictor** directory contains the *ui.r* and *server.r* files for the text prediction application, which was created in RStudio using the Shiny package. The application can be viewed at [fentontaylor.shinyapps.io/textPredictor/](https://fentontaylor.shinyapps.io/textPredictor/).
- *modelTraining.R* contains all the code to fully reproduce the data splitting and N-gram list creation.
- *functions.R* contains all the custom functions implemented in model training.
- *MilestoneReport1.Rmd* is the first assignment for the project and performs initial exploratory analysis. The compiled HTML version of the code can be viewed at [RPubs](http://rpubs.com/fentontaylor/251753).
- *capstonePresentation.md* is the reproducible pitch of the application. HTML version can be viewed [here](http://rpubs.com/fentontaylor/261942).

## Update
I wrote the code several years ago, before I had studied at Turing School of Software and Design. I am still proud of the functionality of the code, but now that I have a greater understanding of the principles of OOP and software design, I realize there are many things I would do differently If I were to start this project over with my current knowledge. In the following sections, I will provide examples of how this project could be improved.

### Testing
There is zero testing for this project. If I were to start over, I would use TDD to drive development of the functions and algorithms. There are several packages available for testing in R. RUnit, Testing, and testthat are some of the more popular packages. By creating unit tests for all the functions, I could have more confidence in the performance of my functions and be able to refactor with confidence.

### Classes
Currently, there are only 2 files used for doing all the backend work: functions.R and modelTraining.R. The problem with having so many functions in one file, is that it is easy to lose track of the responsibility of the functions. If they were contained within classes with specific responsibilities, the code would be more encapsulated and logically organized. It would also allow for more organized unit tests of each class, instead of one giant test for all the functions in functions.R.

### Single-Responsibility
Many of the functions in functions.R are far too long and contain the logic for far too many behaviors. For example, the `cleanPCorpus` function is 72 lines long and does the following: creates directories and files, loads the corpus, converts characters, creates temp files, performs multiple transformations of the corpus text, and writes the cleaned corpus to a new file. Each of these responsibilities should be defined in its own function with a descriptive name to abstract and encapsulate that logic. Then, each of those functions could be called inside `cleanPCorpus` or even be split further into 2 or 3 smaller functions. Furthermore, there are too many things happening in modelTraining.R. Whenever something goes wrong, the entire file structure needs to be cleaned up and the entire script run again. With several smaller scripts, the behavior could be isolated and completed iteratively, which would make troubleshooting and re-running scripts far less time-consuming and confusing.

### Function and Variable Naming
There are too many single-letter variables being used throughout this project. The variables `x`, `n`, and `m` have no inherent meaning and make it hard to follow the logic of many of the functions. Furthermore, all of the substitutions using regular expressions and the `tm_map` function could be wrapped in desriptive functions that describe what each function does, like: `deleteHashtags`, `deleteUrls`, `insertEosTags`, `removeExtraneousPunctuation`, etc.

### DRY the Code
There are several instances where I copied and pasted bit of code and changed only a few variables. I now realize this is a red flag, and indicates a piece of functionality that could be encapsulated in its own function. For example, the following bit of code comes from the `create_ngrams` function (and in fact is repeated 4 more times):
```
...

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

...
```
This should really be encapsulated in a function like:
```
create_ngram <- function(name, size, tokens) {
  print( paste("Creating ", name, "grams...") )
  n_toks(toks=tokens, ng=size, name=name, saveDir=mod_dir, saveAll=saveAll)
  print("Complete")
}
```
And then called inside `create_ngrams` like:
```
...
create_ngram("uni", 1, tokens)
create_ngram("bi", 2, tokens)
create_ngram("tri", 3, tokens)
...

```

### Conclusion
The algorithm I wrote to use incorporate the natural language processing model works surprsingly well despite the shortcomings of the code in the project. However, just because it works, does not mean the code is successful. Without testing, class organization, single-responsibility, and empathetic variable/function names, this code would unfortunately be nearly impossible to maintain in a production environment. Luckily, I have learned and incorporated much better design principles in my work at Turing, and hope to continue to improve in every project I touch moving forward.
