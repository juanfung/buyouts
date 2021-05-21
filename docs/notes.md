# Cedar Rapids Buyouts #

## Background ##

- Cedar Rapids experienced severe flooding in June 2008
- Recovery included a federally-funded land acquisition program
     - Idea is to buyout homeowners in flood-prone areas (ie, near Cedar River)
     - Program is *voluntary*
     - Eligibility depends on federal grant (HMGP, CDBG), flood exposure, and 
       benefit-cost ratio 
       [Tate et al. (2015)](https://link.springer.com/article/10.1007/s11069-015-2060-8)
         - **TODO**: Determine eligiility in the data (currently assuming flooded == 
         eligible)
- Based on federal grant and hazard exposure, about 1300 properties acquired
  under one of three designations:
     - Construction Area
     - Greenway Area
     - Neighborhood Revitalization Area
- Properties were acquired over the period 2009-2014
     - Many properties acquired under condition there will be no future
       reconstruction (hence reducing future hazard exposure)
     - [TODO] Check restrictions on how long homeowner can stay *if they reject buyout*
       
## Research questions ##

1. Conditional on eligibility, what drives decision to accept buyout or not?
2. Conditional on accepting, where do owners go?
    - In particular, do people stay in Cedar Rapids or not? Why?
3. Conditional on not accepting, how long do owners stay?
4. Conditional on accepting/not accepting buyout, what is value of owner's
   property in 2016 (relative to pre-flood)?
    - Are people who receive buyout better off or worse off (in terms of
      property value), relative to pre-flood value? people who reject buyout?


## Data ##

- `buyouts.csv`: list of *eligible* properties (assuming flooded == eligible),
  including buyout status, buyout amount (if buyout status = 1), buyout area,
  and annual assessor data
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

See [`docs/tasks.pdf`](https://github.com/juanfung/buyouts/blob/master/docs/tasks.pdf)
