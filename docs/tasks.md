# Cedar Rapids Buyouts #

Modified: 2021-05-21

## Remaining tasks ##

1. Tracking owners and their properties across years
    - Some owners may own multiple properties, or else names are not unique
    - Some owner names are not entered consistently across years
    - The main task is matching names and properties across years 
    - Idea: see https://github.com/juanfung/buyouts/issues/4
2. Getting property characteristics
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

For context, this is a high-level summary of research questions (there likely
are other interesting questions to be asked):

- What do people do?
      - Why do people choose to take or not take the buyout?
      - Where do they go (spatially)?
- Are people better off or worse off (in terms of property value) after the
  buyout?
      - This is conditional on taking or not taking the buyout
      - The same question could be asked about amenities (e.g., lower assessed
        value because of less square footage, but closer to parks or in a better
        school district)

For SURF, it might be a good idea to focus on (1) preparing the data for
analysis and (2) preparing some visualizations of the data, with the research
questions in mind. Depending on time, we can go further:

1. Exploratory analysis
      - Summary statistics: Summarizing {property value, damage} by {acquired,
        not acquired}, both pre- and post-buyouts (e.g., 2007 vs 2015)
      - Visualization opportunities (graphs and maps)
2. Statistical analysis
      - ANOVA: can we identify how those who accept are different from those who
        reject buyout (on average)?
      - PCA or Factor analysis: similar question
3. Econometrics
     - Potential plan A: focus on (1) buyout decision and (2) post-buyout home
        value | buyout decision (NB: no temporal aspect; simpler spec)
      - https://floswald.github.io/ScPo-Labor/notes.html

