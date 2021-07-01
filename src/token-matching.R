## Sample code to match tokenized names to names in assessor data

###################
## Load packages ##
###################

library('dplyr')
library('ggplot2')
library('sf')
library('here')

###############
## Set paths ##
###############

path_raw = here('data', 'raw')
path_processed = here('data', 'processed')

## Load assessor data
assess = readRDS(file=file.path(path_processed, 'assessor/linn_cr_all.rds'))

## Load tokenized buyout data
## - Let's assume the data with tokens is called df_tokens
df_tokens = readRDS(file.path(path_processed, 'df_tokens.rds'))

## buyouts = readRDS(file.path(path_processed, 'buyouts.rds'))

##############################
## 1. Let's assume the token column is id_token

## get each token is unique
tokens = df_tokens %>%
    dplyr::pull(id_token) %>%
    unique()

## 176847 unique names
assess_names = assess %>%
    dplyr::pull(DeedOwner) %>%
    unique()


###############################
## 2. Let's iterate through each token

## for testing
df_tokens = data.frame(id_token=rep(1:2, 2),
                       DeedOwner=c('Smith Bob', 'Jones Alice',
                                   'Smith Bob', 'Jones Alice P'))

tokens = df_tokens %>%
    dplyr::pull(id_token) %>%
    unique()

test_names = c('Smith Bob',
               'Jones Alexa',
               'Jones Alice P',
               'Smith Robert',
               'Smith Bob E',
               'Jones Alice Partridge',
               'Jones A P',
               'Smith B')

## Empty list of matches
matched_names = list()

## Iterate through tokens and find approximate matches
## TODO: how to match when there are two owners?
for (token in tokens) {
    ## Get list of names associated with token
    token_names = df_tokens %>%
        dplyr::filter(id_token == token) %>%
        dplyr::distinct(DeedOwner) %>%
        dplyr::pull(DeedOwner)
    #####################################
    ## Check for matches in assess
    ## - Let's start with agrep, which uses Levenshtein distance
    ##     - https://stat.ethz.ch/R-manual/R-devel/library/base/html/agrep.html
    ##     - Key parameters:
    ##         - max.distance: see documentation
    ##         - fixed: use literal or use regular expressions
    ##     - If we wanted to calculate the distances and select ourselves, we can use adist
    ##       but results should be the same
    ##     - https://stat.ethz.ch/R-manual/R-devel/library/utils/html/adist.html
    ## - If we want more control over the approximate matching...
    ##     - We can try the package stringdist
    ##     - It has more metrics than Levenshetein; I've used it before, we can discuss 
    #####################################
    ## This returns a vector of potential matches
    matched_names[[token]] = c(unlist(
        sapply(token_names,
               agrep,
               test_names,
               ## assess_names,
               value=TRUE)))
}
