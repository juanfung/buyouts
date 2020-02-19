## Combine Varsha's data into a single table
## Table of {owners, properties} across 2007-2016
## with buyout status and assessor data

library("tidyr")
library("readr")
library("readxl")
library("dplyr")
library("lubridate")
library("data.table")
library("sf")
library("here")

## flood map
flooded = sf::read_sf(here::here("data", "raw", "floodmaps-2008", "FloodAffectedParcels.shp"))

## assessor data
assess = readRDS(file=here::here("data", "processed", "assessor", "linn_cr_all.rds"))

## 1. List of eligible properties with buyout status
## ## parsing failure!
## acquired = readr::read_csv(here::here("data", "processed", "varsha",
##                                 "ParcelAcquiredMatched_06-11.csv"),
##                            col_types=cols(TAXPIN=col_character())) %>%
##     dplyr::rename(GPN=TAXPIN)

acquired = fread(here::here("data", "processed", "varsha",
                      "ParcelAcquiredMatched_06-11.csv"),
                 colClasses=c(TAXPIN="character"))
setnames(acquired, old="TAXPIN", new="GPN")

acquired =
    acquired %>%
    tibble::as_tibble() %>%
    dplyr::rename(
               Address=FULLADD,
               buyout_area=buyout,
               ## buyout_status=bought,
               val_preflood=val107,
               val_appeal=AppealVal,
               val_buyout=ActVal,
               Class=zone) %>%
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


## 2. list of owners that accepted buyouts tracked annually
pb = readRDS(here::here("data", "processed", "varsha", "postBuyoutData.rds"))

## TODO: Add {OwnerID, OwnerParcelID}
pb = lapply(1:length(pb), function(j) pb[[j]]["OID"] = j) 

pb = pb%>%
    dplyr::bind_rows() %>%
    dplyr::rename(Owner=DeedOwner)

readr::write_csv(pb, path=here::here("data", "processed", "varsha",
                               "post_buyoyt.csv"))

## 3. list of owners/parcels NOT bought out
## nb = not bought
## the following tables should be reshaped (wide to long) and joined:

## owner names for each parcel
## TODO: add {OwnerID, OwnerParcelID} column...
nb_names = readr::read_csv(here::here("data", "processed", "varsha",
                                "TrackingNotBoughtProperties.csv"),
                           col_types=cols(GPN=col_character()))

## OR...add when reshaping
nbn_long = nb_names %>%
    tidyr::pivot_longer(
               -c(GPN, Address),
               names_to = c(".value", "Year"),
               names_pattern = "(.*)\\.(\\d{4})",
               ## values_drop_na = TRUE
               ) %>%
    dplyr::rename(Owner=DeedOwner)


## assessor infor for each parcel
nb_vals = readr::read_csv(here::here("data", "processed", "varsha",
                               "NotBoughtProperties_MatchedToAssessors.csv"),
                          col_types=cols(GPN=col_character()))

cols_drop = grep("Linn$", colnames(nb_vals), value=TRUE)

nbv_long = nb_vals %>%
    dplyr::select(-cols_drop) %>%
    tidyr::pivot_longer(
               -c(GPN, City, Class),
               names_to = c(".value", "Year"),
               names_pattern = "(.*)\\.(\\d{2})",
               ## values_drop_na = TRUE
           ) %>%
    dplyr::mutate(Year = paste0("20", Year))

nb_all =
    nbn_long %>%
    ## assumes we don't need the DeedOwner uid {or} uid is same as nb_vals
    dplyr::select(-uid) %>%
    dplyr::left_join(nbv_long, by=c("GPN", "Address", "Year")) 

## TODO: combine acquired with owner and assessor data
buyout_df = acquired %>%
    dplyr::filter(bought != 0) %>%
    dplyr::mutate(buyout_decision=case_when(bought == 1 ~ "Yes", bought == -1 ~ "No")) %>%
    dplyr::select(-bought, -date, -ID.ACQ, -CombID) 

buyout_yes = pb %>%
    dplyr::filter(Year==2015) %>%
    dplyr::select(-uid) %>%
    dplyr::left_join(buyout_df,
                     ## PROBLEM: names are not matching
                     ## SOLUTION:
                     ## In Varsha's original wide data, add a unique Owner ID
                     ## Then match name in acquired to any name in pb/nb -> Owner ID
                     ## TODO: add 2007/2008 assessor data to pb
                     by=c("Owner"))
    
## TODO: add column about buyout status (i.e., eligible, zone, not bought, etc)
##       - pb
##       - nb_all
##       - easiest to join with acquired
## TODO: row_bind with (pb, nb_all)

## Two-step plan:
## 1. Simpler specification (buyout decision -> post-buyout value)
##    - Data prep: join acquired to (pb, nb_all) but don't need all years
## 2. More complex: (buyout decision -> where do people move?)
## 

###############################################################
## the data.table way...
## I still like this,
## but there's gotta be a better way to get the year column
year_dt = data.table(variable=1:10, Year=2007:2016)

nbn_wide = melt(setDT(nb_names),
               measure=patterns(c("^DeedOwner", "uid")),
               value.name=c("Owner", "UID"))


nbn_wide = merge(nbn_wide, year_dt, by="variable", all.x=TRUE)

nb_vals[,(cols_drop):=NULL]

nbv_wide = melt(setDT(nb_vals),
                measure=patterns(c("^Address", "^Acres", "^val_land", "^val_impr", "^val_total", "^uid")),
                value.name=c("Address", "Acres", "val_land", "val_impr", "val_total", "UID"))

nbv_wide = merge(nbv_wide, year_dt, by="variable", all.x=TRUE)
