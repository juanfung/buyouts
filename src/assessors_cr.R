## NB: old code, needs updating

library(data.table)
## TODO: what functions in utils.r are used here?
source("../utils.r")

## TODO: update paths using "here"
apath = "./Assessors/"
afiles = list.files(apath, pattern="csv$", full.names=TRUE)

## Import each file into a list
pre_years = as.character(2007:2009)
post_years = as.character(2010:2016)
all_years = c(pre_years, post_years)

alist = vector("list", length=length(all_years))
names(alist) = all_years

suppressWarnings(
    for (i in 1:length(alist)) {
        yr = all_years[i]
        alist[[yr]] = fread(afiles[i], check.names=TRUE)
        ## alist[[yr]][, AssessYear := yr]
    }
)

## sapply(alist, dim)

## Standardize names across pre/post
for (yr in post_years) {
    alist[[yr]][, Land := "0"]
}

pre_names = names(alist[["2007"]])
post_names = names(alist[["2016"]])

val_cols = c("Land", "Dwelling", "Improvements", "Total", "Com.Land", "Res.Land")
assess_vals = setdiff(post_names, val_cols)
new_col_order = c(assess_vals, val_cols)

for (yr in post_years) {
    setcolorder(alist[[yr]], neworder=new_col_order)
}

post_names = names(alist[["2016"]])

pre_names_new = post_names[1:length(pre_names)]

for (yr in pre_years) {
    setnames(alist[[yr]], old=names(alist[[yr]]), new=pre_names_new)
}


## Convert string to numeric, assign AssessYear
for (yr in all_years) {
    alist[[yr]][, AssessYear := as.numeric(yr)]
    for (v in val_cols) {
        if (yr %in% post_years | !(v %in% c("Com.Land", "Res.Land"))) {
            alist[[yr]][, (v) := as.num.char(get(v))]
        }
    }
}


## Create land_val for 2010 - 2016
## NB: 2007 - 2009 only have combined res_land_val + com_land_val
for (yr in post_years) {
    alist[[yr]][, Land := get("Com.Land") + get("Res.Land")]
}


## Add Parcel Data File labels for pre years
pdf_names = fread("pdf_names.txt")

for (yr in pre_years) {
    alist[[yr]][, PDF_Num := PDF_Name + 1] # to match table
    alist[[yr]][, PDF_Name := NULL] # for type consistency
    alist[[yr]] = merge(alist[[yr]], pdf_names, by="PDF_Num", all.x=TRUE)
}


## Combine all data.tables
acr = rbindlist(alist, use.names=TRUE, fill=TRUE)
setnames(acr, old=names(acr), new=gsub("\\.", "_", names(acr)))

## create unique ID = PN + Year
acr[, UniqueID := paste(Parcel_Number, AssessYear, sep="_")]



## Combine res / com Year Built
## NB: many NA!

## acr[, Year_Built : = min ... ?]



## NB: Parcel numbers change over time....!
##     How to match parcels?



## Geocoding

## Get table of unique addresses
## NB: some addressess need cleaning?
## unique_pn = acr[, unique(Parcel_Number)]

addresses = unique(
    acr[,.(Parcel_Number,
           StreetAddress=paste(House_Number, Address))]
)

addresses[, StreetAddress := gsub("^(0 )", "", StreetAddress)]

addresses[,`:=`(City="Cedar Rapids",
                State="IA",
                Zip="")]

## geocoder-script.r

library(httr)

return_type = 'geographies' ## locations

census_url = paste0('https://geocoding.geo.census.gov/geocoder/',
                    return_type,
                    '/addressbatch')

batch_file = "../test.csv"


post_benchmark = "Public_AR_Census2010"
post_vintage = "Census2010_Census2010"


loc_cols = c("Parcel_Number", "InputAddress", "MatchStatus", "MatchType",
             "ResultAddress", "Coordinates", "TigerID", "Side")

geo_cols = c(loc_cols, "StateFIPS", "CountyFIPS", "CensusTract", "CensusBlock")

return_cols = list("geographies"=geo_cols,
                   "locations"=loc_cols)

sleep_param = 3


r = POST(census_url,
         body=list(
             ## format="jsonp", ## ignored
             ## output="test_result.txt", ##ignored
             addressFile = upload_file(batch_file),
             benchmark = post_benchmark,
             vintage = post_vintage
         ),
         encode="multipart", verbose())



## parse results
res = content(r, "text", encoding = "UTF-8")
res = strsplit(res, split="\n")
##res = strsplit(gsub('\\"', "", res), split="\n")
## res_list = strsplit(res, split="\n")
## res_list = sapply(res_list, function(x) strsplit(x, split='\\\\",'))

## NB: DO THIS ONCE AT THE END

test_df = data.table(Res=res[[1]])

test_df[, (return_cols[[return_type]]) := tstrsplit(Res, split='\\",\\"')]

for (i in names(test_df)) {
    test_df[, (i) := gsub('\\"', '', get(i))]
}
## ALSO SPLIT LAT/LON -> numeric



## res_df = data.table(ResultRaw = res)
## res_df[, (return_cols[[return_type]]) := res]


## For large number of records:
bigN = nrow(addresses)
idx = split(1:bigN, ceiling(seq_along(1:bigN)/1000))


## TODO: wrap in function
res_df = data.table(Res=character(0))
for (i in idx) {
    ## i. loop through address data.frame
    ##    1000 per iteration -> addies
    addies = addresses[i]
    ## ii. write addresses to tempfile
    tempfile = tempfile(fileext = ".csv")
    write.csv(addies, tempfile, row.names = FALSE)
    ## iii. post request
    res = POST(census_url,
               body=list(
                   ## format="json", ## ignored
                   ## output="test_result.txt", ## ignored
                   addressFile = upload_file(tempfile),
                   benchmark = post_benchmark,
                   vintage = post_vintage
               ),
               ## verbose(),
               encode="multipart"
               )
    ## iv. parse results
    res = strsplit(content(res, "text", encoding = "UTF-8"), split="\n")
    ## v. save results to data.frame
    res_df = rbindlist(list(res_df, res))
    print(paste("Geocoded", i[1], "thru", i[1000]))
    Sys.sleep(sleep_param)
}
print("Done!")

## vi. separate results

res_df[, (return_cols[[return_type]]) := tstrsplit(Res, split='\\",\\"')]

for (i in names(res_df)) {
    res_df[, (i) := gsub('\\"', '', get(i))]
}

lon_lat = c("Longitude", "Latitude")

res_df[, (lon_lat) := lapply(tstrsplit(Coordinates, split=","),
                             as.num.char)]

res_df[, GeoID := paste0(StateFIPS, CountyFIPS, CensusTract, CensusBlock)]


## vii. merge
add_cols = c("Parcel_Number",
             "ResultAddress",
             "Side",
             "GeoID",
             "Longitude",
             "Latitude")

acr = merge(acr,
            res_df[,.SD,.SDcols=add_cols],
            by="Parcel_Number",
            all.x=TRUE)



## Areas of interest:
## CGE:
##  Downtown / NewBo / Czech Village
## Econometrics:
##  acquisition zones (have addresses within)
##  want proximity: addresses BARELY NOT eligible
##  people that moved vs people that did not


## 0. NEED CRS (WGS84 will do...)
## 1. create SpatialPolygons objects for each area
## 2. overlay parcel coordinates
## 3. create SpatialPoylgonsDataFrame?


saveRDS(acr, file="assessor_all.rds")
