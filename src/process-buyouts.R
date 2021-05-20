## Combine table of flooded (eligible for buyout) properties,
## table of acquired properties,
## and assessor data.
## Track owners by year and buyout status (yes, no)

library("tidyr")
library("readr")
library("readxl")
library("dplyr")
library("purrr")
library("lubridate")
library("data.table")
library("sf")
library("ggplot2")
library("here")

## set paths
path_raw = here('data', 'raw')
path_processed = here('data', 'processed')

## Load map of flood-affected parcels
flooded = sf::read_sf(file.path(path_raw, 'floodmaps-2008/FloodAffectedParcels.shp'))

## Load assessor data
assess = readRDS(file=file.path(path_processed, 'assessor/linn_cr_all.rds'))

## assessor data, unique by {parcel number, address, year}
assess_unique = assess %>%
    dplyr::distinct(GPN, Address, Year, .keep_all=TRUE)

## Get path to table of acquired properties
acquired_path = list.files(path_raw,
                           pattern="^Properties.*xlsx$",
                           full.names=TRUE)

## 1. Create table of eligible properties
## flood-affected parcels, unique by {parcel number, address}
flooded_df = flooded %>%
    sf::st_drop_geometry() %>%
    ## drop vacant lots
    dplyr::filter(!grepl("^0", FULLADD)) %>%
    dplyr::rename(Address=FULLADD,
                  GPN=TAXPIN) %>%
    dplyr::select(GPN, Address, MGMTAREA) %>%
    dplyr::distinct(GPN, Address, .keep_all=TRUE)

## merge with assessor by {parcel number, address}
## 1. Begin with 2008 as base for "pre-flood value" in buyouts
##    - these are the "eligible" properties
## 2. Given matched properties in 2008, match all years by matched GPN
## 3. TODO: Drop residential owned by ROCKWELL?
flooded_2008 = flooded_df %>%
    dplyr::semi_join(
               ## assess_unique,
               dplyr::filter(assess_unique, Year==2008),
               by=c('GPN', 'Address')) 

eligible_annual = flooded_2008 %>%
    dplyr::inner_join(
               assess_unique,
               ## NB: Matching by GPN only results in
               ## ~2000 mis-matched addresses
               by=c('GPN', 'Address'))

## save
readr::write_csv(eligible_annual, file.path(path_processed, 'eligible_annual.csv'))

saveRDS(eligible_annual, file.path(path_processed, 'eligible_annual.rds'))

##########################################################
## NB: Given ambiguity in matching the unmatched,
## going to ignore for set of eligible

## Some addresses don't match...
flooded_anti = flooded_df %>%
    dplyr::anti_join(
               ## assess_unique
               dplyr::filter(assess_unique, Year==2008),
               by=c('GPN', 'Address'))

## Match the unmatched by GPN only
## - only matches 5 residential (non-vacant), none in acquired
flooded_anti_gpn = flooded_anti %>%
    dplyr::inner_join(
               dplyr::filter(assess_unique, Year==2008),
               by='GPN')

## Match the unmatched by Address only
## - only matches 3 residential (2 unique), none in acquired
flooded_anti_addy = flooded_anti %>%
    dplyr::inner_join(
               dplyr::filter(assess_unique, Year==2008),
               by='Address')
##########################################################



## 2. Load table of acquired properties

## clean up column names, re-format address and date
acquired = readxl::read_excel(acquired_path) %>%
    dplyr::rename(
               buyout_owner=UQ("Owner Name"),
               buyout_address=UQ("Flood Address"),
               val_preflood=UQ("107% Pre-flood value"),
               val_appeal=UQ("Appeal Value"),
               val_buyout=UQ("Award Amount"),
               buyout_date=UQ("Date of Final IEDA Award"),
               buyout_class=Zoning) %>%
    dplyr::mutate(
               buyout_address=toupper(buyout_address),
               buyout_date=as.Date(buyout_date, format="%m/%d/%Y")) %>%
    dplyr::mutate(
               buyout_year=lubridate::year(buyout_date)) %>%
    dplyr::filter(!grepl('VACANT', buyout_address))

## TODO: manually fix a couple of addresses for matching
acquired = acquired %>%
    dplyr::mutate(buyout_address=gsub('^(72 & 72 1/2)(.*)$', '72\\2', buyout_address)) %>%
    dplyr::mutate(buyout_address=gsub('^(208-210)(.*)$', '208\\2', buyout_address))

acquired_2008 = acquired %>%
    ## TODO: manually match `51.*17TH AVE SW
    dplyr::filter(!grepl('^51.*17TH AVE SW', buyout_address)) %>%
    dplyr::inner_join(
               dplyr::filter(assess_unique, Year==2008),
               by=c('buyout_address'='Address')) %>%
    dplyr::pull(GPN)

acquired_annual = acquired %>%
    dplyr::inner_join(
               dplyr::filter(assess_unique, GPN %in% acquired_2008),
               by=c('buyout_address'='Address'))

## check umatched
## NB: only one residential unmatched, it's the one that has to be done manually!
acquired %>%
    dplyr::anti_join(
               dplyr::filter(assess_unique, Year==2008),
               by=c('buyout_address'='Address')) %>%
    dplyr::count(buyout_class)

## Now manually match `51.*17TH AVE SW
acquired_manual = acquired %>%
    dplyr::filter(grepl('^51.*17TH AVE SW', buyout_address))

assess_manual = assess_unique %>%
    dplyr::filter(Year==2008 & grepl('^51.*17TH AVE SW', Address))

gpn_manual = assess_manual %>%
    dplyr::filter(val_total < 40000) %>%
    dplyr::pull(GPN)

assess_manual = assess_unique %>%
    dplyr::filter(grepl('^51.*17TH AVE SW', Address)) %>%
    dplyr::mutate(Address=case_when(
                      GPN == gpn_manual ~ '51 1/2 17TH AVE SW',
                      TRUE ~ Address))

acquired_manual = acquired_manual %>%
    dplyr::inner_join(assess_manual,
                      by=c('buyout_address'='Address'))

acquired_annual = acquired_annual %>%
    dplyr::bind_rows(acquired_manual) %>%
    dplyr::mutate(buyout_status=1L)

## save
readr::write_csv(acquired_annual, file.path(path_processed, 'acquired_annual.csv'))

saveRDS(acquired_annual, file.path(path_processed, 'acquired_annual.rds'))

## 3. Combine eligible and acquired to get list of buyout status {1=Y, 0=N}
## TODO: Add MGMTAREA to acquired_annual
acquired_gpn = acquired_annual %>%
    dplyr::distinct(GPN) %>%
    dplyr::pull()

eligible_acquired = eligible_annual %>%
    dplyr::filter(GPN %in% acquired_gpn) %>%
    dplyr::distinct(GPN, Address, MGMTAREA)

acquired_annual = acquired_annual %>%
    ## NB: 219 2ND AVE SE (Commercial)
    ##     - No MGMTAREA
    ##     - buyout_status == 1
    dplyr::left_join(eligible_acquired, by='GPN')

buyouts = eligible_annual %>%
    dplyr::filter(!(GPN %in% acquired_gpn)) %>%
    dplyr::bind_rows(acquired_annual) %>%
    dplyr::mutate(buyout_status=
                      case_when(is.na(buyout_status) ~ 0L,
                                TRUE ~ buyout_status),
                  buyout_zone=
                      case_when(grepl('^Construction', MGMTAREA) ~ 'Construction',
                                grepl('^Greenway', MGMTAREA) ~ 'Greenway',
                                grepl('^Neighborhood', MGMTAREA) ~ 'Neighborhood',
                                TRUE ~ MGMTAREA)
                  )

## save
readr::write_csv(buyouts, file.path(path_processed, 'buyouts.csv'))

saveRDS(buyouts, file.path(path_processed, 'buyouts.rds'))

                 
######################################################
## Sanity checks 
## one additional row for 51 1/2 17TH AVE SW
eligible_annual %>%
    dplyr::filter(!(GPN %in% acquired_gpn)) %>%
    dplyr::bind_rows(acquired_annual) %>%
    dplyr::filter(Year == 2008) %>%
    dplyr::count(buyout_status)

## equivalent
buyouts %>%
    dplyr::filter(Year == 2008) %>%
    dplyr::count(buyout_status)

## only 2 properties in {acquired} \ {eligible}:
## - the one fixed manually above
## - a commercial property 219 2ND AVE SE
acquired_annual %>%
    dplyr::filter(Year == 2008) %>%
    dplyr::select(GPN, buyout_address) %>%
    dplyr::anti_join(dplyr::filter(eligible_annual, Year==2008),
                      by=c('GPN', 'buyout_address'='Address'))

    ## dplyr::inner_join(dplyr::select(dplyr::filter(acquired_annual, Year==2008),
    ##                                 GPN, Year, buyout_address)) %>%
    ## NB: Some of acquired_annual not merged with eligible (???)
    dplyr::inner_join(acquired_annual, by=c('Year', 'GPN', 'Address'='buyout_address'))


######################################################

## 4. Filter (single-family) residential
## TODO: Decide if assessor class is only class to be trusted
## TODO: Drop 'residential' if owner is ROCKWELL COLLINS
class_residential = c('Residential', 'RESIDENTIAL')

residential_gpn = buyouts %>%
    dplyr::filter(
               Year == 2008 &
               ## NB: 1 property : Class==res, buyout_class==comm
               ##     - 610 J AVE NW (no google street view)
               (Class %in% class_residential |
               ## NB: 2 properties : Class==comm, buyout_class==res
               ##    - 1621 10TH ST NW (looks residential)
               ##    - 213 13TH AVE SW (looks residential)
               buyout_class %in% class_residential)) %>%
    dplyr::pull(GPN)

buyouts_res = buyouts %>%
    dplyr::filter(GPN %in% residential_gpn)

owners_df = buyouts_res %>%
    dplyr::filter(!grepl('^ROCKWELL', DeedOwner)) %>%
    dplyr::distinct(DeedOwner)

owners_2008 = buyouts_res %>%
    ## Only need to track eligible owners
    ## + filter out obvious commercial owners
    dplyr::filter(!grepl('^ROCKWELL', DeedOwner) & (Year == 2008)) %>%
    ## key id: {DeedOwner}
    ## dplyr::distinct(DeedOwner)
    ## key id: {GPN x DeedOwner}
    dplyr::distinct(GPN, DeedOwner)

owners_accepted = buyouts_res %>%
    dplyr::filter(!grepl('^ROCKWELL', buyout_owner, ignore.case=TRUE) &
                  !is.na(buyout_owner)) %>%
    ## NB: coerce toupper()
    dplyr::distinct(buyout_owner)


## 5. Tokenize names
## TODO: Count unique owners, grouped by GPN
buyouts_res %>%
    dplyr::group_by(GPN) %>%
    dplyr::summarise(no_owners=n_distinct(DeedOwner)) %>%
    dplyr::count(no_owners) %>%
    dplyr::ungroup() 

## Step 1: Normalize names (ie, remove symbols, abbrevs, etc)
##      1b: Create lookup table containing tokenized names [2008]?
##          - Based on "simplifying" names?
##      1c: [TODO] Look into Record Linkage
## Step 2: Compute distances between names
## Step 3: Fuzzy matching
