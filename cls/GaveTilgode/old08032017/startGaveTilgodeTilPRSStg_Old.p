/* startGaveTilgodeTilPRSStg.p.*/

USING cls.*.

DEFINE VARIABLE dDato AS DATE NO-UNDO.

ASSIGN 
    dDato = 02/01/2017 /* Today */
    .
                                          
DEFINE VARIABLE rGaveTilgodeTilPRSStg AS CLASS cls.GaveTilgode.GaveTilgodeTilPRSStg NO-UNDO. 

rGaveTilgodeTilPRSStg = NEW cls.GaveTilgode.GaveTilgodeTilPRSStg( dDato ) NO-ERROR.

