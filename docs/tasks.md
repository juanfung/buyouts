# Cedar Rapids Buyouts #

Modified: 2019-10-03

## Remaining tasks ##

1. ~~Matching names~~
      - For homeowners that did not accept a buyout, where are they post-buyout?
      - Now that you've matched properties that were targeted but not acquired
        to owners, we can see if the owner is the same (or not) post-buyout,
        i.e., after 2014
      - If a property owner changes over this period, do they remain in the
        Cedar Rapids area?
      - This would be very much like the name matching you did before: match
        *names* to the assessor data 
      - Varsha completed: `TrackingNotBoughtProperties.csv`
2. ~~Matching PINs~~
      - Now that we have a list of owners and their eligible properties (acquired or
        not), as well as their properties post-buyout, it's time to determine
        the *values* of those properties
      - This should be straightforward: match parcel ID (TAXPIN or GPN) back to
        assessor data and get the "improved value" (this is the value of the
        structure, in contrast to the value of the land)
      - I should be able to do this fairly quickly (unless you have time!)
      - Varsha completed: `NotBoughtProperties_MatchedToAssessors.csv`
3. TODO: combine 1 and 2
      - reshape 1 wide to long
      - reshape 2 wide to long and join (property values) to 1 by (year, PIN)
      - row bind? to `post_buyout.csv` (itself a row bind of list in
        `postBuyoutData.rds`), which tracks owners of acquired properties
      - combine with `ParcelAcquiredMatched_6-11.csv`, the list of acquired
        properties matched to PIN. 
      - TODO: add assessor data from `post_buyout.csv`
      - TODO: check list of owners of acquired properties NOT IN `post_buyout.csv`
4. Parcel flood levels
      - Damage information (maybe?)
      - ~~This is in the original GIS data (`parcels.shp`) in the column
        `FLOODRECOR`, but I'm not clear on what the units are. I'll reach out to
        Cedar Rapids GIS~~
             - This is a record ID
      - ~~Flood stage map?~~ 
             - Useless: only shows peak flood stage 31.12 ft
5. Getting property characteristics
      - The assessor data we have includes assessed property values (important),
        but not information on the actual property such as square footage,
        number of bedrooms, etc. (also important)
      - Scraping: I've scraped their website before...not fun
      - Alternative is to simply ask for the data. They've already provided part
        of the assessor data, why wouldn't they share the rest of it...?
        
## Models ##

Research questions

1. Conditional on eligibility, what drives decision to accept buyout or not?
2. Conditional on accepting, where do owners go?
3. Conditional on not accepting, how long do owners stay?
4. Conditional on accepting/not accepting buyout, what is value of owner's
   property in 2016 (relative to pre-flood)?

Models

1. Discrete choice! Flooding/eligibility is random assignment; agent chooses [Y,
   N], based on expected future value of home, moving costs, ...?
2. Location decision? Stay in Cedar Rapids or not? Distance?
3. Stopping problem? (problem: buyout program ends 2015, data only thru 2016)
4. Hedonic
        
## Analysis ##

Not exclusive list. Open to ideas!

For context, these are the main research questions I'm considering at the moment
(there likely are other interesting questions to be asked):

- What do people do?
      - Why do people choose to take or not take the buyout?
      - Where do they go (spatially)?
- Are people better off or worse off (in terms of property value) after the
  buyout?
      - This is conditional on taking or not taking the buyout
      - The same question could be asked about amenities (e.g., lower assessed
        value because of less square footage, but closer to parks or in a better
        school district)

1. Exploratory analysis
      - Summary statistics: Summarizing {property value, damage} by {acquired,
        not acquired}, both pre- and post-buyouts (e.g., 2007 vs 2015)
      - Graphs!
2. Econometrics
     - Potential plan A: focus on (1) buyout decision and (2) post-buyout home
        value | buyout decision (NB: no temporal aspect; simpler spec)
      - https://floswald.github.io/ScPo-Labor/notes.html

