
/* Temp-table definisjon */
DEFINE TEMP-TABLE tmpGavetilgodeHode NO-UNDO LIKE-SEQUENTIAL GaveTilgodeHode BEFORE-TABLE beforeGavetilgodeHode.
DEFINE TEMP-TABLE tmpGavetilgodelinje NO-UNDO LIKE-SEQUENTIAL GaveTilgodeLinje BEFORE-TABLE beforeGaveTilgodeLinje.
