/* startGaveTilgodeTilPRSStg.p.*/

USING cls.*.

DEFINE VARIABLE dDato AS DATE NO-UNDO.

ASSIGN 
    dDato = TODAY /* TODAY  - Angi en dato. Det er måneden i datoen som blir benyttet. Normalt settes denne til TODAY. */
    .
                                          
DEFINE VARIABLE rGaveTilgodeTilPRSStg AS CLASS cls.GaveTilgode.GaveTilgodeTilPRSStg NO-UNDO. 

rGaveTilgodeTilPRSStg = NEW cls.GaveTilgode.GaveTilgodeTilPRSStg( dDato ) NO-ERROR.

