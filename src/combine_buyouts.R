## Combine Varsha's data into a single table
## Table of {owners, properties} across 2007-2016
## with buyout status and assessor data

library("tidyr")
library("readr")
library("readxl")
library("dplyr")
library("purrr")
library("lubridate")
library("data.table")
library("sf")
library("here")
library("ggplot2")

## flood map
flooded = sf::read_sf(here::here("data", "raw", "floodmaps-2008", "FloodAffectedParcels.shp"))

## assessor data
assess = readRDS(file=here::here("data", "processed", "assessor", "linn_cr_all.rds"))

## 1. List of eligible properties with buyout status
## ## parsing failure!
## eligible = readr::read_csv(here::here("data", "processed", "varsha",
##                                 "ParcelAcquiredMatched_06-11.csv"),
##                            col_types=cols(TAXPIN=col_character())) %>%
##     dplyr::rename(GPN=TAXPIN)

eligible = fread(here::here("data", "processed", "varsha",
                      "ParcelAcquiredMatched_06-11.csv"),
                 colClasses=c(TAXPIN="character"))


eligible =
    eligible %>%
    tibble::as_tibble() %>%
    dplyr::rename(
               GPN=TAXPIN,
               buyout_address=FULLADD,
               buyout_area=buyout,
               ## buyout_status=bought,
               val_preflood=val107,
               val_appeal=AppealVal,
               val_buyout=ActVal,
               buyout_class=zone,
               buyout_owner=Owner) %>%
    dplyr::mutate(buyout_date=case_when(
                      date %in% "1111-11-11" ~ NA_character_,
                      TRUE ~ date),
                  buyout_status=case_when(
                      bought %in% -1 ~ "No",
                      bought %in% 0 ~ "Vacant",
                      bought %in% 1 ~ "Yes")) %>%
    ## dplyr::select(-c(date, bought)) %>%
    dplyr::mutate(buyout_date=as.Date(buyout_date, format="%m/%d/%Y")) %>%
    dplyr::mutate(buyout_year=lubridate::year(buyout_date))

assess_2007 = assess %>%
    dplyr::filter(Year == 2007) %>%
    dplyr::distinct(GPN, Address, .keep_all=TRUE)

## Alternative: loop through rows of eligible and flag duplicate matches
eligible_assess = eligible %>%
    ## drop vacants
    dplyr::filter(!(buyout_status %in% 'Vacant')) %>%
    dplyr::nest_join(assess_2007,
                     by=c('GPN'='GPN', 'buyout_address'='Address'))

## TODO: clean up names
eligible_sub = eligible %>%
    dplyr::select(GPN, DeedOwner=Owner, Address, MGMTAREA, Class,
                  buyout_area, bought, date, buyout_status, buyout_year)

## accepted_df = acquired_all %>%
##     dplyr::inner_join(eligible_sub)


## 2. list of owners that accepted buyouts tracked annually
## accepted = accepted buyout
accepted_list = readRDS(here::here("data", "processed", "varsha", "postBuyoutData.rds"))

## drop empty tibbles
accepted_list = Filter(function(x) nrow(x) > 0, accepted_list)

## TODO: Add {OwnerID, OwnerParcelID}
accepted_list = lapply(1:length(accepted_list),
                       function(j) accepted_list[[j]]["OID"] = j) 

## TODO: add pre-buyout assessor data
accepted = accepted_list %>%
    dplyr::bind_rows() %>%
    dplyr::rename(Owner=DeedOwner)

readr::write_csv(accepted, path=here::here("data", "processed", "varsha",
                               "accepted_post_buyout.csv"))

## 3. list of owners/parcels NOT bought out
## rejected = rejected buyout
## the following tables should be reshaped (wide to long) and joined:

## owner names for each parcel
## TODO: add {OwnerID, OwnerParcelID} column...
rejected_names = readr::read_csv(here::here("data", "processed", "varsha",
                                "TrackingNotBoughtProperties.csv"),
                           col_types=cols(GPN=col_character()))

## OR...add when reshaping
rejected_names_long = rejected_names %>%
    tidyr::pivot_longer(
               -c(GPN, Address),
               names_to = c(".value", "Year"),
               names_pattern = "(.*)\\.(\\d{4})",
               ## values_drop_na = TRUE
               ) %>%
    dplyr::rename(Owner=DeedOwner)


## assessor infor for each parcel
rejected_vals = readr::read_csv(here::here("data", "processed", "varsha",
                               "NotBoughtProperties_MatchedToAssessors.csv"),
                          col_types=cols(GPN=col_character()))

cols_drop = grep("Linn$", colnames(rejected_vals), value=TRUE)

rejected_vals_long = rejected_vals %>%
    dplyr::select(-cols_drop) %>%
    tidyr::pivot_longer(
               -c(GPN, City, Class),
               names_to = c(".value", "Year"),
               names_pattern = "(.*)\\.(\\d{2})",
               ## values_drop_na = TRUE
           ) %>%
    dplyr::mutate(Year = paste0("20", Year))

rejected_all =
    rejected_names_long %>%
    ## assumes we don't need the DeedOwner uid {or} uid is same as rejected_vals
    dplyr::select(-uid) %>%
    dplyr::left_join(rejected_vals_long, by=c("GPN", "Address", "Year")) 

## TODO: combine eligible with owner and assessor data
buyout_df = eligible %>%
    dplyr::filter(bought != 0) %>%
    dplyr::mutate(buyout_decision=case_when(bought == 1 ~ "Yes", bought == -1 ~ "No")) %>%
    dplyr::select(-bought, -date, -ID.ACQ, -CombID) 

buyout_yes = accepted %>%
    dplyr::filter(Year==2015) %>%
    dplyr::select(-uid) %>%
    dplyr::left_join(buyout_df,
                     ## PROBLEM: names are not matching
                     ## SOLUTION:
                     ## In Varsha's original wide data, add a unique Owner ID
                     ## Then match name in eligible to any name in accepted/rejected -> Owner ID
                     ## TODO: add 2007/2008 assessor data to accepted
                     by=c("Owner"))
    
## TODO: add column about buyout status (i.e., eligible, zone, not bought, etc)
##       - accepted
##       - rejected_all
##       - easiest to join with eligible
## TODO: row_bind with (accepted, rejected_all)

## Two-step plan:
## 1. Simpler specification (buyout decision -> post-buyout value)
##    - Data prep: join eligible to (accepted, rejected_all) but don't need all years
## 2. More complex: (buyout decision -> where do people move?)
## 

###############################################################
## the data.table way...
## I still like this,
## but there's gotta be a better way to get the year column
year_dt = data.table(variable=1:10, Year=2007:2016)

rejected_names_wide = melt(setDT(rejected_names),
               measure=patterns(c("^DeedOwner", "uid")),
               value.name=c("Owner", "UID"))


rejected_names_wide = merge(rejected_names_wide, year_dt, by="variable", all.x=TRUE)

rejected_vals[,(cols_drop):=NULL]

rejected_vals_wide = melt(setDT(rejected_vals),
                measure=patterns(c("^Address", "^Acres", "^val_land", "^val_impr", "^val_total", "^uid")),
                value.name=c("Address", "Acres", "val_land", "val_impr", "val_total", "UID"))

rejected_vals_wide = merge(rejected_vals_wide, year_dt, by="variable", all.x=TRUE)
