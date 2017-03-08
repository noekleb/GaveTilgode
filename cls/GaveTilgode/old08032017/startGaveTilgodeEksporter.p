/* startGaveTilgodeEksporter.p.*/

USING cls.*.
                                          
DEFINE VARIABLE cLogg AS CHARACTER NO-UNDO.
DEFINE VARIABLE bOk AS LOG NO-UNDO.
DEFINE VARIABLE dDato AS DATE NO-UNDO.
DEFINE VARIABLE rGaveTilgodeEksporter AS cls.GaveTilgode.GaveTilgodeEksporter NO-UNDO. 
DEFINE VARIABLE rStandardFunksjoner AS cls.StdFunk.StandardFunksjoner NO-UNDO.
DEFINE VARIABLE rdsGaveTilgodeDef AS cls.GaveTilgode.dsGaveTilgodeDef NO-UNDO.


ASSIGN
    dDato      =  02/08/2017  
    cLogg      = 'GaveTilgodeEksporter' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
    .
    
rStandardFunksjoner = NEW cls.StdFunk.StandardFunksjoner() NO-ERROR.

rStandardFunksjoner:SkrivTilLogg(cLogg, 
    'Start startGaveTilgodeEksporter.'
    ). 

rGaveTilgodeEksporter = NEW cls.GaveTilgode.GaveTilgodeEksporter( INPUT dDato ).

rStandardFunksjoner:SkrivTilLogg(cLogg, 
    'Ferdig startGaveTilgodeEksporter.'
    ). 
