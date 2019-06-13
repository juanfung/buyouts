# Cedar Rapids Buyouts #

## Background ##

- Cedar Rapids experienced severe flooding in June 2008
- Recovery included a federally-funded land acquisition program
     - Idea is to buyout homeowners in flood-prone areas (ie, near Cedar River)
     - Program is *voluntary*
- Based on federal grant and hazard exposure, about 1500 properties identified
  for buyout under one of three designations:
     - Construction Area
     - Greenway Area
     - Neighborhood Revitalization Area
- Properties were acquired over the period 2009-2012
     - Many properties acquired under condition there will be no future
       reconstruction (hence reducing future hazard exposure)
       
## Research questions ##

- Conditional on being identified for acquisition, why do some people choose
  buyout?
      - Need info on damage
      
- Conditional on receiving buyout, where do people go?
      - In particular, do people stay in Cedar Rapids or not? Why?
      - Are people who receive buyout better off or worse off (in terms of
        property value)?
        

## Data ##

- `Properties Acquired.xslx`: list of 1356 properties acquired, including owner,
  address, and award
- `XXX Area Address List.pdf`: list of *eligible* properties by buyout area
  (Construction Area, Greenway Area, Neighborhood Revitalization Area)
- Assessor data for Cedar Rapids and Linn County, 2007-2016: parcel-level data
  including address, owner, land value, building value
- GIS data
      - parcels (I've matched to assessor data)
      - boundaries
      - 2008 flood extent
      - flooded parcels, including buyout area designation

## Immediate tasks ##

The immediate goal is to identify properties and their owners *across time*,
to see who got a buyout and where they went

- Match parcel-level assessor data (owner names and addresses) with
      - Lists of properties (owner names and addresses) identified for land
        acquisition
      - Properties (owner names and addresses) that received a buyout
- GIS data on flooded parcels does not include all of the parcels identified for
  buyout
  
The most time-consuming effort will be going through the PDFs that identify
eligible properties and matching this to assessor data. 

GIS data on eligible properties can be matched to GIS parcel data (which I've
been able to mostly match to assessor data) for a second check.
