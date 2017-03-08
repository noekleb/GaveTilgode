 
 /*------------------------------------------------------------------------
    File        : OppdaterPRSStgFraInfopos
    Purpose     : Samle alle oppdateringsfunksjoner mot PRSStg i et klassebibliotek.
    Syntax      : 
    Description : Metoder for oppdatering av PRSStg fra Infopos databasen.
    Author(s)   : tny
    Created     : Thu Apr 28 15:27:46 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING cls.*.

CLASS cls.GaveTilgode.OppdaterPRSStgFraInfopos:
    DEFINE VARIABLE moStandardFunksjoner AS cls.StdFunk.StandardFunksjonerInfopos NO-UNDO.

    DEFINE VARIABLE dDato      AS DATE NO-UNDO.
    DEFINE VARIABLE dStartDato AS DATE NO-UNDO.
    DEFINE VARIABLE dSluttDato AS DATE NO-UNDO.
      
	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/
						
	CONSTRUCTOR PUBLIC OppdaterPRSStgFraInfopos ( INPUT pdDato AS DATE ):
		SUPER ().

        /* Starter opp og gjør tilgjengelig. */
        moStandardFunksjoner = NEW cls.StdFunk.StandardFunksjonerInfopos().
        
        ASSIGN 
            dDato = pdDato 
            .
            
        /* Finner første dag i forrige måned. */
        IF MONTH(TODAY) > 1 THEN
                dStartDato = DATE(MONTH(pdDato) - 1,1,YEAR(pdDato)).
        ELSE 
            /* Eller første dag siste måned forrige år. */
            dStartDato = DATE(12,1,YEAR(pdDato) - 1).

        /* Finner siste dag i forrige måned. */
        dSluttDato = DATE(MONTH(pdDato),1,YEAR(pdDato)) - 1.            

	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdaterGavekort( INPUT  iValgtBut AS INTEGER,
                                            OUTPUT iAnt      AS INTEGER ):
        DEFINE VARIABLE bOk       AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE iButNr    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i2butNr   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cBuffDiff AS CHARACTER NO-UNDO.

        ASSIGN 
            bOk    = TRUE
            .
                                             
        GAVELOOP:
        FOR EACH Gavekort NO-LOCK WHERE
            GaveKort.BruktDato >= dStartDato AND
            gavekort.bruktdato <= dSluttDato AND  
            gavekort.brukttid  >= 0 AND  
            Gavekort.ButNr      = iValgtBut:
                  
            ASSIGN 
                iButNr  = gavekort.ButNr
                i2butNr = gavekort.FrabutNr
                .      
                  
            /* Retter opp feil butikknr. */
            iButNr  = moStandardFunksjoner:RetterOppFeilButikknr(iButNr).
            i2ButNr = moStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND GavetOgTilgode NO-LOCK WHERE 
                GavetOgTilgode.Transtype = 1 AND 
                GavetOgTilgode.ButNr     = iButNr AND 
                GavetOgTilgode.IdentNr   = GaveKort.IdentNr AND 
                GavetOgTilgode.SekvensNr = GaveKort.SekvensNr NO-ERROR.
            
            IF NOT AVAILABLE GavetOgTilgode THEN 
            DO TRANSACTION:
                CREATE GavetOgTilgode.
                BUFFER-COPY Gavekort
                    EXCEPT ButNr FrabutNr 
                    TO GavetOgTilgode 
                    ASSIGN 
                    GavetOgTilgode.TransType = 1
                    GavetOgTilgode.ButNr     = iButNr
                    GavetOgTilgode.FrabutNr  = i2ButNr
                    .
                FIND CURRENT GavetOgTilgode NO-LOCK.
                iAnt = iAnt + 1.
            END. /* TRANSACTION */
            ELSE IF AVAILABLE GavetOgTilgode THEN 
                DO:
                    cBuffDiff = ''.
                    BUFFER-COMPARE 
                        GavetOgTilgode 
                        EXCEPT Transtype butNr FraButNr 
                        TO Gavekort
                        SAVE cBuffDiff.
                    IF cBuffDiff <> '' THEN
                    DO TRANSACTION:
                        FIND CURRENT GavetOgTilgode EXCLUSIVE-LOCK.
                        BUFFER-COPY Gavekort
                            EXCEPT butNr FrabutNr  
                            TO GavetOgTilgode
                            ASSIGN 
                            GavetOgTilgode.ButNr     = iButNr
                            GavetOgTilgode.FrabutNr  = i2ButNr
                            . 
                        FIND CURRENT GavetOgTilgode NO-LOCK.
                        iAnt = iAnt + 1.
                    END. /* TRANSACTION */
                END.
        END. /* GAVELOOP */
		
		RETURN bOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdaterNyeGavekort( INPUT  iValgtBut AS INTEGER,
                                               OUTPUT iAnt      AS INTEGER ):
		
        DEFINE VARIABLE bOk       AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE iButNr    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i2butNr   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cBuffDiff AS CHARACTER NO-UNDO.
        DEFINE VARIABLE dDato     AS DATE      NO-UNDO.

        ASSIGN 
            bOk = TRUE
            .
                                             
        GAVELOOP:
        FOR EACH Gavekort NO-LOCK WHERE
            Gavekort.ButNr      = iValgtBut AND 
            gavekort.dato       >= dStartDato AND 
            gavekort.dato       <= dSluttDato: 
                  
            ASSIGN 
                iButNr  = gavekort.ButNr
                i2butNr = gavekort.FrabutNr
                .      
                  
            /* Retter opp feil butikknr. */
            iButNr  = moStandardFunksjoner:RetterOppFeilButikknr(iButNr).
            i2ButNr = moStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND GavetOgTilgode NO-LOCK WHERE 
                GavetOgTilgode.Transtype = 1 AND 
                GavetOgTilgode.ButNr     = iButNr AND 
                GavetOgTilgode.IdentNr   = GaveKort.IdentNr AND 
                GavetOgTilgode.SekvensNr = GaveKort.SekvensNr NO-ERROR.
            
            IF NOT AVAILABLE GavetOgTilgode THEN 
            DO TRANSACTION:
                CREATE GavetOgTilgode.
                BUFFER-COPY Gavekort
                    EXCEPT ButNr FrabutNr 
                    TO GavetOgTilgode 
                    ASSIGN 
                    GavetOgTilgode.TransType = 1
                    GavetOgTilgode.ButNr     = iButNr
                    GavetOgTilgode.FrabutNr  = i2ButNr
                    .
                FIND CURRENT GavetOgTilgode NO-LOCK.
                iAnt = iAnt + 1.
            END. /* TRANSACTION */
        END. /* GAVELOOP */
        
        RETURN bOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Oppdaterer nye og endrede poster fra Infopos.Tilgode til 
	          PRSStg.GavetOgtilgode.
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdaterTilgode(INPUT  iValgtBut AS INTEGER, 
	                                      OUTPUT iAnt      AS INTEGER ):
		
		DEFINE VARIABLE bOk       AS LOGICAL NO-UNDO.
        DEFINE VARIABLE iButNr    AS INTEGER NO-UNDO.
        DEFINE VARIABLE i2butNr   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cBuffDiff AS CHARACTER NO-UNDO.

        ASSIGN 
            bOk    = TRUE
            .
        
        TILGODELOOP:
        FOR EACH Tilgode NO-LOCK WHERE
            Tilgode.BruktDato >= dStartDato AND
            tilgode.bruktdato <= dSluttDato AND  
            tilgode.brukttid  >= 0 AND  
            Tilgode.ButNr = iValgtBut: 

            ASSIGN 
                iButNr  = Tilgode.ButNr
                i2butNr = Tilgode.FrabutNr
                .      
                  
            /* Retter opp feil butikknr. */
            iButNr  = moStandardFunksjoner:RetterOppFeilButikknr(ibutNr).
            i2ButNr = moStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND GavetOgTilgode NO-LOCK WHERE 
                GavetOgTilgode.Transtype = 2 AND 
                GavetOgTilgode.ButNr     = iButNr AND 
                GavetOgTilgode.IdentNr   = Tilgode.IdentNr AND 
                GavetOgTilgode.SekvensNr = 0 NO-ERROR.
            
            IF NOT AVAILABLE GavetOgTilgode THEN 
            DO TRANSACTION:
                CREATE GavetOgTilgode.
                BUFFER-COPY Tilgode
                    EXCEPT ButNr FrabutNr
                    TO GavetOgTilgode 
                    ASSIGN 
                    GavetOgTilgode.TransType = 2
                    GavetOgTilgode.butNr     = iButNr
                    GavetOgTilgode.FraButNr  = i2ButNr
                    GavetOgTilgode.SekvensNr = 0
                    .
                FIND CURRENT GavetOgTilgode NO-LOCK.
                iAnt = iAnt + 1.
            END. /* TRANSACTION */
            ELSE IF AVAILABLE GavetOgTilgode THEN 
                DO:
                    cBuffDiff = ''.
                    BUFFER-COMPARE 
                        GavetOgTilgode 
                        EXCEPT Transtype butNr FrabutNr SekvensNr 
                        TO Tilgode
                        SAVE cBuffDiff.
                    IF cBuffDiff <> '' THEN
                    DO TRANSACTION:
                        FIND CURRENT GavetOgTilgode EXCLUSIVE-LOCK.
                        BUFFER-COPY Tilgode
                            EXCEPT butNr FrabutNr    
                            TO GavetOgTilgode
                            ASSIGN 
                            GavetOgTilgode.butNr     = iButNr
                            GavetOgTilgode.FraButNr  = i2ButNr
                            .
                        iAnt = iAnt + 1.
                    END. /* TRANSACTION */
                    FIND CURRENT GavetOgTilgode NO-LOCK.
                END.
        END. /* TILGODELOOP */

		RETURN bOk.

	END METHOD.

	DESTRUCTOR PUBLIC OppdaterPRSStgFraInfopos ( ):

	END DESTRUCTOR.

END CLASS.