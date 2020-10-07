## bind rows for all years

library("here")
library("dplyr")
library("tibble")
library("readxl")
library("readr")

#########################################################
## get full paths to asssessor data
path_assessors_linn = list.files(here("data", "raw", "assessors", "linn-county"),
                               pattern=".*20.*.xlsx$",
                               full.names=TRUE)

#########################################################
## load full CR assessor data
assessors_cr = readRDS(here("data", "processed", "assessor", "cr_all.rds")) %>%
    as.tibble()

assessors_cr = assessors_cr %>%
    ## standardize column names
    dplyr::mutate(Class=toupper(Class)) %>%
    dplyr::mutate(GPN=gsub("-", "", Parcel_Number),
                  Year=as.character(AssessYear),
                  YearBuilt=case_when(Class %in% "RESIDENTIAL" ~ Res_Yr_Built,
                                      TRUE ~ Commercial_Year_Blt),
                  DeedOwner=Deedholder,
                  Address=paste(House_Number, Address),
                  City="Cedar Rapids",
                  val_land=Land,
                  val_impr=case_when(Class %in% "RESIDENTIAL" ~ Dwelling,
                                     TRUE ~ Improvements),
                  val_total=Total,
                  uid=paste0("assess-cr-", seq_len(n()))) %>%
    dplyr::select(uid, GPN, DeedOwner, Class, Address, City, Acres,
                  Year, YearBuilt, val_land, val_impr, val_total)



#########################################################
## list_assessors_linn = list()
## for (p in path_assessors_linn) {
##     ## get assessor year from path
##     year = gsub(".*(20\\d{2}).*", "\\1", p)
##     message(paste("Year is ", year))
##     df_tmp = readxl::read_excel(path=p)
##     message(paste(names(df_tmp), collapse=", "))
##     list_assessors_linn[[paste0("Linn-", year)]] = df_tmp
##     message("Done.\n")
## }


#########################################################
## loading Linn assessor data
## create empty list
list_assessors_linn = list()

## loop throught list of paths
## NB:
##   - no Year built
##   - no Acres for 2014
for (p in path_assessors_linn) {
    ## get assessor year from path
    year = gsub(".*(20\\d{2}).*", "\\1", p)
    print(paste("Year is ", year))
    ## read in the data and add Year column
    df_tmp = readxl::read_excel(path=p) %>%
        dplyr::mutate(Year=year) 
    ## standardize column names
    if (year == "2014") {
        df_tmp = df_tmp %>%
            dplyr::mutate(val_impr=AssessedDw + AssessedBu) %>%
            dplyr::rename(DeedOwner=owners,
                          Class=PropertyCl,
                          val_land=AssessedLa,
                          val_total=TotalAsses) %>%
    dplyr::select(GPN, DeedOwner, Class, Year, val_land, val_impr, val_total)
    } else if (year == "2015") {
        df_tmp = df_tmp %>%
            dplyr::rename(Address=SitusAddress,
                          City=SitusCity,
                          DeedOwner=Owner,
                          val_land=CurrentLandValue,
                          val_impr=CurrentImprovedValue,
                          val_total=CurrentTotalValue,
                          Acres=AssessedAcres) %>%
    dplyr::select(GPN, DeedOwner, Class, Address, City, Acres,
                  Year, val_land, val_impr, val_total)
    } else if (year == "2016") {
        df_tmp = df_tmp %>%
            dplyr::rename(Address=SitusAddre,
                          City=SitusCity,
                          DeedOwner=Owner,
                          val_land=CurrentLan,
                          val_impr=CurrentImp,
                          val_total=CurrentTot,
                          Acres=AssessedAc) %>%
    dplyr::select(GPN, DeedOwner, Class, Address, City, Acres,
                  Year, val_land, val_impr, val_total)
    } else {
        df_tmp = df_tmp %>%
            dplyr::rename(Acres=AssessedAc,
                          val_land=LandValue,
                          val_impr=BuildingVa,
                          val_total=TotalValue) %>%
    dplyr::select(GPN, DeedOwner, Class, Address, City, Acres,
                  Year, val_land, val_impr, val_total)
    }
    print(names(df_tmp))
    print("Done.\n")
    ## add data to list
    list_assessors_linn[[paste0("Linn-", year)]] = df_tmp
}

## once all the data is in the list, bind rows:
assessors_linn = dplyr::bind_rows(list_assessors_linn) %>%
    ## add unique id
    dplyr::mutate(uid=paste0("assess-linn-", seq_len(n()))) 
    

#########################################################
## combining with Cedar Rapids

assessors_all = assessors_linn %>%
    dplyr::bind_rows(assessors_cr)

#########################################################
## save...
saveRDS(assessors_linn, file=here("data", "processed", "assessor", "linn_all.rds"))
saveRDS(assessors_all, file=here("data", "processed", "assessor", "linn_cr_all.rds"))
