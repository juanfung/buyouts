flooded_parcels = sf::st_read("flooded/flooded_parcels.shp")
fp = flooded_parcels[,c(1,3,4,7)]
fp = data.frame(TAXPIN = as.character(fp$TAXPIN),MGMTAREA = as.character(fp$MGMTAREA),
                FULLADD = as.character(fp$FULLADD),buyout = as.character(fp$buyout),stringsAsFactors = FALSE)

library(readxl)
acq = read_excel("PropertiesAcquired_CRGazette09142014.xlsx")
acq$`Flood Address` = str_to_upper(acq$`Flood Address`)
acq$uid.acq = paste(str_pad(1:nrow(acq), 4, side="left", pad=0), "ACQ", sep="-")
acq$`Owner Name` = str_to_upper(acq$`Owner Name`)

# fixing mistakes
acq[acq$`Flood Address` == "208-210 5TH AVE SW",2] = "208 5TH AVE SW"
# acq[acq$`Flood Address` == "51 1/2 17TH AVE SW",2] = "51 17TH AVE SW"
fp[4359,3] = "51 1/2 17TH AVE SW"
acq[acq$`Flood Address` == "72 & 72 1/2 15TH AVE SW",2] = "72 15TH AVE SW"
# acq.novac = acq[!str_detect(acq$`Flood Address`, "Vacant"),]
# acq.novac$`Flood Address` = str_to_upper(acq.novac$`Flood Address`)
# # there are 1327 UNIQUE properties in acq.novac

# alternatively, for every property in fp, the goal is to match it to a bought property in acq or declare it as not bought

findProp = function(prop) {
  b = 0
  # doa = as.POSIXct(strptime("1111-11-11", "%Y-%m-%d"),tz="UTC")
  doa = NA
  val107 = 0
  AppealVal = 0
  ActVal = 0
  Owner = "UnknownOwner"
  id = "UnknownID"
  z = "UnknownZone"
  if (str_detect(prop, "VACANT")){
    b = 0
  } else if (prop %in% acq$`Flood Address`) {
    b = 1
    dt = acq[acq$`Flood Address` == prop,]
    doa = dt$`Date of Final IEDA Award`
    val107 = as.numeric(dt$`107% Pre-flood value`)
    AppealVal = as.numeric(dt$`Appeal Value`)
    ActVal = as.numeric(dt$`Award Amount`)
    Owner = dt$`Owner Name`
    id = dt$uid.acq
    z = dt$Zoning
  } else {
    b = -1
  }
  ret = data.frame(bought = as.character(b), date = as.character(doa), val107 = val107, AppealVal = AppealVal, 
                   ActVal = ActVal, Owner = Owner, zone = z, ID.ACQ = id,stringsAsFactors = FALSE)
  ret
}

info = lapply(fp$FULLADD, findProp)
info1 = bind_rows(info)
matched = cbind(fp, info1)
matched$CombID = paste(str_pad(1:nrow(matched), 4, side="left", pad=0), "PAR", sep="-")

write.csv(matched, "ParcelAcquiredMatched_06-11.csv", row.names = FALSE)

mistakes = acq$`Flood Address`[!(acq$`Flood Address` %in% matched$FULLADD)]


