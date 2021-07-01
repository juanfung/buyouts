## Sample code to map buyout-eligible properties

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

####################
## Get file paths ##
####################

landrecs = list.files(file.path(path_raw, "GIS/landrecords"),
                      pattern="\\.shp$",
                      full.names=TRUE)

cousub = list.files(file.path(path_raw, "GIS/census"),
                    pattern="\\.shp$",
                    full.names=TRUE)

roads = list.files(file.path(path_raw, "GIS/highways"),
                   pattern="\\.shp$",
                   full.names=TRUE)


#######################
## Load spatial data ##
#######################

## For re-projecting the other files
iowa_counties = sf::st_read(cousub[[grepl("500k", cousub)]])

## load county, and municipal boundaries
county = sf::st_read(landrecs[[grep("County", landrecs)]]) %>%
    sf::st_transform(sf::st_crs(iowa_counties))

muni = sf::st_read(landrecs[[grep("Municipality", landrecs)]]) %>%
    sf::st_transform(sf::st_crs(iowa_counties))

## address shapefile (points)
addy = sf::st_read(landrecs[[grep("Address", landrecs)]]) %>%
        sf::st_transform(sf::st_crs(iowa_counties))

## Roads:
road_net = sf::st_read(roads[grep("Road", roads)]) %>%
    sf::st_transform(sf::st_crs(iowa_counties))


##########################################
## Map parcels and municipal boundaries ##
##########################################

## ## get bounding box for Cedar Rapids
## muni_cr = muni %>%
##     sf::st_make_valid() %>%
##     dplyr::filter(TOWNSHIP %in% "Cedar Rapids") %>%
##     dplyr::mutate(Town=factor(TOWNSHIP))

ggplot()+
    geom_sf(data=muni) +
    geom_sf(data=addy, aes(colour=JURISDICTI), alpha=0.5) +
    theme_bw() +
    theme(legend.position='bottom')
