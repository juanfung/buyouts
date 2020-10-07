options(scipen = 999)
setwd("\\\\elwood.campus.nist.gov/730/users/vnv/My Documents/CedarRapids")
library(stringr)
library(dplyr)

apm = read.csv("ParcelAcquiredMatched_06-11.csv", stringsAsFactors = FALSE,na.strings=c("","NA"))
apm$Owner = gsub(" AND ", " & ", apm$Owner)
apm$Owner = gsub("[.]", "", apm$Owner)
apm$Owner = gsub("[,]", "", apm$Owner)
## `apm` is the list of 7750 properties that were eligible for buyout, including the matched info
## of 1326 properties that were actually bought out.
## values of apm$bought: 1 is bought, -1 is kept, 0 is vacant
bought = apm[apm$bought == 1,] # 1326 properties that were bought
kept = apm[apm$bought == -1,] # 5711 properties that were kept

assess = readRDS("linn_cr_all_wValue.rds")
assess$City = str_to_upper(assess$City)
assess$City[str_detect(assess$City, "CEDAR RAP")] = "CEDAR RAPIDS IA"
assess = (assess %>% distinct(GPN, DeedOwner, Class, Address, City, Year, .keep_all = TRUE))

# First, dealing with the properties that were kept
########################################################################################################################
####### CHANGING KEPT PROPERTIES TO A DATA FRAME WITH INFORMATION FOR EACH YEAR AS COLUMNS AND TAXPINS AS ROWS #########
########################################################################################################################

dups = unique(kept$FULLADD[duplicated(kept$FULLADD)]) # Assumption is that duplicated addresses are multi-residential
kept = kept[!(kept$FULLADD) %in% dups,] # 4900 non-multi residential places
nrow(kept[(kept$TAXPIN / 100000) %% 1 != 0,] )  ## == 132
## 132 properties have TAXPINS that make it seem like they're multi-residential? will be kept though

# for every TAXPIN in kept (not bought properties) identify its owner (and value) in 2007 - 2016
findInfo = function(num) {
  if (num %% 100 == 0) {
    print(num)
  }
  pin = kept$TAXPIN[num]
  # add = kept$FULLADD[num]
  ret = (assess[which(assess$GPN == pin),])
  ret
}
keptinfo = lapply(1:length(kept$TAXPIN), findInfo) # Assessors data for each TAXPIN that was kept
# 9 kept properties do not have assessors data

# Use Levenshtein edit distance (fuzzy string matching) to identify owners
# In agrep(), as you increase max.distance, you're lowering the threshold for saying two strings are the same
# i.e. it's easier to say that strings are the same

changeOwners = function(info, thresh = 0.3) {
  if (nrow(info) <= 1) {
    return(info)
  }
  owners = info$DeedOwner
  # For each owner, identify the owner names that "match" to that name or "split" versions of that name
  for (i in 1:length(owners)) {
    
    sim = agrepl(owners[i], owners, thresh)
    owners[sim] = owners[i]
  }
  info$DeedOwner = owners
  info
}
keptinfo_new = lapply(keptinfo, changeOwners)
# diffOwn2 = lapply(keptinfo_new, function(x) unique(x$DeedOwner))
names(keptinfo) = names(keptinfo_new) =  kept$TAXPIN
names(keptinfo_new)[sapply(keptinfo_new, nrow) == 0] # TAXPINS THAT DON'T HAVE DATA

# For each taxpin (i.e. each item in keptinfo) we want to change it from a dataframe to a single row of data,
# that has information for each year from 2007 to 2016
sum(sapply(keptinfo, function(x) {
  if (nrow(x)==0){
    return(TRUE)
  }
  yr = x$Year
  v = tapply(seq_along(yr), yr, identity)[unique(yr)]
  if (sum(sapply(v, length) == 1)){
    return(TRUE)
  }
  return(length((which(sapply(v, length) > 1)))==1 & names(which(sapply(v, length) > 1))=="2015")
  # TRUE if the only year with more than 1 data pt is 2015
  
}))
# Result: The only year with more than 1 data point ever is 2015

sum(sapply(keptinfo, function(x){
  dta = x[x$Year==2015,]
  if (nrow(dta) <= 1){
    return(TRUE)
  } else {
    uids = dta$uid
    if (sum(str_detect(uids,"linn"))==1 & sum(str_detect(uids,"cr"))==1){
      return(TRUE)
    } else {
      return(FALSE)
    }
  }
  
}))
# Result: If there is more than one data point for 2015, one of them is always CR data and the other is Linn County data

infoPerYear = c("Address", "Acres", "val_land", "val_impr", "val_total","DeedOwner", "uid") 
cnames_base = rep(rep(c("Address", "Acres", "val_land", "val_impr", "val_total","DeedOwner", "uid")), 11)
years_string = rep(str_pad(c(7:15,15:16), width = 2, side = "left", pad = "0"), each = length(cnames_base)/11)
cnames_base = paste(cnames_base, years_string, sep = "." )
cnames_base[duplicated(cnames_base)] = paste(cnames_base[duplicated(cnames_base)], "Linn", sep = ".")
cnames_base = c(c("GPN", "City", "Class"), cnames_base)
empty = setNames(data.frame(matrix( ncol = length(cnames_base), nrow = 1)), cnames_base)

changeKeptInfo = function(tp) {
  # For each TAXPIN, keep the Class, DeedOwner, val_land, val_impr, val_total, uid, and YearBuilt for each year
  # Some TAXPINS have two observations for a single year, or none for a particular year
  info = keptinfo[[tp]]
  dta = empty
  dta$GPN = tp
  if (nrow(info) == 0){
    return(dta)
  }
  dta$City = paste(unique(info$City), collapse="/")
  dta$Class = paste(unique(info$Class), collapse="/")
  # For each year, isolate that data
  do2015 = FALSE
  for (y in 2007:2016){
    thisYear = info[info$Year==y,infoPerYear]
    if (nrow(thisYear)>1){
      do2015= TRUE
      thisYear = thisYear[str_detect(thisYear$uid, "cr"),]
      if (nrow(thisYear)>1){
        print(tp)
        next
      }
    }
    if (nrow(thisYear)==0){
      next
    }
    colnames(thisYear) = paste(colnames(thisYear), 
                               str_pad(y - 2000, width = 2, side = "left", pad = "0"), sep = ".")
    dta[,colnames(thisYear)] = thisYear
  }
  # Deal with 2015 data
  if (do2015){
    dta2015 = info[info$Year==2015, infoPerYear]
    dta2015 = dta2015[str_detect(dta2015$uid, "linn"),]
    colnames(dta2015) = paste(colnames(dta2015), "15.Linn", sep = ".")
    dta[,colnames(dta2015)] = dta2015
  }
  return(dta)
}
info_trans = lapply(names(keptinfo), changeKeptInfo) # This is based off of original data (before owner names were changed)
names(info_trans) = names(keptinfo)

info_df = bind_rows(info_trans)
write.csv(info_df, "NotBoughtProperties_MatchedToAssessors.csv", row.names = FALSE)
rm(infoPerYear, years_string, dups, d, cnames_base, empty, info_trans)

#######
kept_info = read.csv("NotBoughtProperties_MatchedToAssessors.csv", na.strings = c("","NA"), stringsAsFactors = FALSE)

########################################################################################################
############################    DEALING WITH PROPERTIES THAT WERE BOUGHT    ############################
########################################################################################################

# There are three rows in which every variable in assess is NA -- removing those rows
assess = assess[- which(is.na(assess$GPN) & is.na(assess$DeedOwner) & is.na(assess$Class) & is.na(assess$Address)),]
# Checking if every TAXPIN in bought is in assessors data
a = sapply(1:length(bought$TAXPIN), function(x) {
  tp = bought$TAXPIN[x]
  if (x %% 100 == 0) {
    print(x)
  }
  return( nrow(assess[assess$GPN == tp,]))
})
names(a) = bought$TAXPIN
# Every taxpin has at least 4 observations in the assessors data

# Making sure that each TAXPIN was indeed bought out
# Find the year in which Cedar Rapids "got control of" the property
bo_year = sapply(1:nrow(bought), function(x){
  if (x%%100==0){
    print(x)
  }
  dta = assess[assess$GPN == bought$TAXPIN[x] & !is.na(assess$DeedOwner),]
  ownCR = dta[str_detect(dta$DeedOwner, "CEDAR RAPIDS"),]
  yrs = as.numeric(ownCR$Year)
  return(min(yrs))
})
bought$BO_year = bo_year
# For some, Cedar Rapids seems to have never owned the data (the rows for which bo_year is Inf)
bought_all = bought
bought = bought_all[bought_all$BO_year %in% 2007:2016,]

# Beginning to analyze where owners moved
comp = "(PROPERT)|(TRUST)|(LLC)|(LC)|(ESTATE)|(INC)|(BANK)|(COMPANY)|(LTD)|(BANK)|(INVESTMENT)|(BOYS)"
comp = paste(comp, "(CORP)|(LIMITED)|(LTD)|(TRST)|(BANKRUPTCY)|(CHURCH)|(LLLP)|(FEDERAL)|(FELLOWSHIP)|(FARMS)", sep="|")
names = bought[str_detect(bought$Owner, comp, negate = TRUE),]

num_prop = sapply(unique(names$Owner), function(x){
  return(nrow(names[names$Owner==x,]))
})

# Only look at owners that had only 1 property
names2 = names[!names$Owner %in% names(num_prop[num_prop > 1]),]
num_prop_check = sapply(unique(names2$Owner), function(x) nrow(names2[names2$Owner == x,]))
num_prop_check[num_prop_check != 1] # All of the owners in names2 only had 1 property eligible for buyout

find_assess_own = sapply(1:nrow(names2), function(x){
  if (x%%50==0){
    print(x)
  }
  return(assess[(assess$GPN == names2$TAXPIN[x]) & (assess$Year == (names2$BO_year[x] - 1)), c("DeedOwner")])
})
find_assess_own = unlist(find_assess_own, recursive = FALSE)
names(find_assess_own) = names2$Owner
# The values of find_assess_own are the names as denoted in the assessors data
# The names of the elements in find_assess_own are the original names
# Check if these names match or very random
check_assess_name = sapply(1:length(find_assess_own), function(x) {
  orig_name = names(find_assess_own)[x]
  ass_name = find_assess_own[x]
  if (str_length(orig_name) >= str_length(ass_name)){
    small = ass_name
    large = orig_name
  } else {
    small = orig_name
    large = ass_name
  }
  length(agrep(small, large, max.distance = 0.5))
})
double_check = find_assess_own[check_assess_name == 0]
double_check = data.frame(orig = names(double_check), ass = double_check)
rownames(double_check) = NULL

names3 = names2[check_assess_name == 1,]
find_assess_own[check_assess_name == 1]
names3$AssessOwner = find_assess_own[check_assess_name == 1]

div_assess_yr = lapply(sort(unique(names3$BO_year)), function(x) {
  return(assess[assess$Year >= x,])
})
names(div_assess_yr) = sort(unique(names3$BO_year))
div_assess_yr = lapply(div_assess_yr, function(x) {
  return(x[!is.na(x$DeedOwner),])
})
post_BO_dta = lapply(1:nrow(names3), function(x){
  if (x%%70==0){
    print(x)
  }
  ass_name = names3$AssessOwner[x]
  year_of_bo = names3$BO_year[x]

  afterYear = div_assess_yr[[paste(year_of_bo)]]
  
  name_pieces = strsplit(ass_name, " ")[[1]]
  name_pieces = name_pieces[!name_pieces %in% c("MC", "VON", "VAN", "DER")]
  # print(name_pieces)
  exp1 = paste(name_pieces[1], name_pieces[2], sep = ".*")
  exp2 = paste(name_pieces[2], name_pieces[1], sep = ".*")
  exp = paste(exp1, exp2, sep = "|")
  
  # print("here")
  dta = afterYear[(str_detect(afterYear$DeedOwner, ass_name) | str_detect(afterYear$DeedOwner, exp)) &
                    !is.na(afterYear$DeedOwner),]
  return(dta)
})
names(post_BO_dta) = names3$AssessOwner
length(which(sapply(post_BO_dta, nrow) == 0)) # 274 names do not have data -- perhaps can use agrep to find that data within assess

sapply(post_BO_dta, length)
saveRDS(post_BO_dta, file = "postBuyoutData.rds")
