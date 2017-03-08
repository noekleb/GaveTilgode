/* startGaveTilgodeTilPRSStg.p.*/

USING cls.*.
                       
DEFINE VARIABLE iX    AS INTEGER   NO-UNDO.       
DEFINE VARIABLE cTxt  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLogg AS CHARACTER NO-UNDO.
                                          
DEFINE VARIABLE rStandardFunksjoner AS cls.StdFunk.StandardFunksjoner NO-UNDO.
DEFINE VARIABLE rGaveTilgodePrep AS CLASS cls.GaveTilgode.GaveTilgodePrep NO-UNDO. 

ASSIGN  
    cLogg = 'GaveTilgodePrep' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
    .

rStandardFunksjoner = NEW cls.StdFunk.StandardFunksjoner() NO-ERROR.
rGaveTilgodePrep     = NEW cls.GaveTilgode.GaveTilgodePrep() NO-ERROR.
DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
    cTxt = '** Start GaveTilgodePrep - FeilNr: '+ STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
    rStandardFunksjoner:SkrivTilLogg(cLogg,
        '    ' + cTxt 
        ).
END.            

