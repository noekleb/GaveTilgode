 
 /*------------------------------------------------------------------------
    File        : standardfunksjoner
    Purpose     : 
    Syntax      : 
    Description : Generelt procedurebibliotek
    Author(s)   : tny
    Created     : Thu Apr 28 14:06:07 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

/* BLOCK-LEVEL ON ERROR UNDO, THROW. */

CLASS cls.StdFunk.StandardFunksjonerInfopos: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    DEFINE STREAM Ut.
		
	CONSTRUCTOR PUBLIC StandardFunksjonerInfopos (  ):
		SUPER ().
		
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose: Henter liste med aktive butikker.
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOG HentListeAktiveButikker(INPUT        cSkipLst AS CHARACTER,
	                                          INPUT-OUTPUT cButLst  AS CHARACTER ):
        
        DEFINE VARIABLE iButNrForste AS INTEGER NO-UNDO.
        DEFINE VARIABLE ibutNrSiste  AS INTEGER NO-UNDO.
        DEFINE VARIABLE bOk          AS LOG     NO-UNDO.
        
        ASSIGN 
            iButNrForste = 899
            iButNrSiste  = 11899
            .
        
        /* Er ikke listen initiert fra før, skal den initieres. */
        IF cButLst = '' THEN 
        DO:
            /* I Prod skal releveante butikker tas med */
            IF SEARCH('tnc.txt') = ? THEN 
            BUTLOOP:
            FOR EACH Butikk NO-LOCK WHERE
                Butikk.butNr > iButNrForste AND 
                Butikk.ButNr < iButNrSiste AND 
                CAN-FIND(FIRST Lager OF Butikk) AND 
                CAN-FIND(FIRST ButVare OF Butikk):
  
                /* Butikker som ikke skal være med i kontrollen. */
                IF CAN-DO(cSkipLst,STRING(Butikk.ButNr)) THEN 
                    NEXT BUTLOOP.
  
                /* Bygger liste over butikker som skal kontrolleres */
                IF NOT CAN-DO(cButlst,STRING(Butikk.butNr)) THEN 
                    ASSIGN cButLst = cbutLst + ',' + STRING(Butikk.ButNr).  
            END. /* BUTLOOP*/  
            
            /* I test skal alle butikker tas med */
            ELSE DO:
                BUTLOOP_TEST:
                FOR EACH Butikk NO-LOCK WHERE
                    Butikk.butNr > iButNrForste AND 
                    Butikk.ButNr < iButNrSiste:
  
                    /* Butikker som ikke skal være med i kontrollen. */
                    IF CAN-DO(cSkipLst,STRING(Butikk.ButNr)) THEN 
                        NEXT BUTLOOP_TEST.
  
                    /* Bygger liste over butikker som skal kontrolleres */
                    IF NOT CAN-DO(cButlst,STRING(Butikk.butNr)) THEN 
                        ASSIGN cButLst = cbutLst + ',' + STRING(Butikk.ButNr).  
                END. /* BUTLOOP_TEST */
            END.  
            
            ASSIGN 
                cButLst = TRIM(cbutLst,',')
                bOk     = TRUE
                .
        END.

        RETURN bOk.

	END METHOD. /* HentListeAktiveButikker */

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC INTEGER RetterOppFeilButikknr( INPUT iButNr AS INTEGER ):

        DEFINE VARIABLE iOldButNr AS INTEGER NO-UNDO.
        		
        IF iButNr > 0 AND iButNr < 11000 THEN 
        DO:
            iOldButNr = iButNr.
        
            IF iButNr <= 999 THEN 
                iButNr = 11000 + iButNr.
            ELSE IF (iButNr > 999 AND iButNr <= 1999) THEN
                    iButNr = iButNr + 10000.        
        
            FIND Butikk NO-LOCK WHERE 
                Butik.ButNr = iButNr NO-ERROR.
            /* Ukjent butikk? - Da lar vi det som er feil stå */
            /*
            IF NOT AVAILABLE Butikk THEN
                iButNr = iOldButNr.
            */
        END.		
		RETURN iButNr.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOG SjekkOmDbErOppkoblet(INPUT pcDbLst AS CHARACTER,
	                                       INPUT pcLogg  AS CHARACTER ):
	    DEFINE VARIABLE piLoop AS INTEGER  NO-UNDO.
        DEFINE VARIABLE pbOk   AS LOG      NO-UNDO.

        pbOk = TRUE.

        IF pcDbLst = '' THEN 
            pbOk = FALSE.
            
        IF pbOk = TRUE THEN 
        DO piLoop = 1 TO NUM-ENTRIES(pcDbLst):
            IF NOT CONNECTED(ENTRY(piLoop,pcDbLst)) THEN
            DO:
                pbOk = FALSE.
                IF pcLogg <> '' THEN  
                    SkrivTilLogg(pcLogg, 
                        '  ** Ingen kontakt med DB ' + ENTRY(piLoop,pcDbLst) + '.'   
                        ). 
            END.
        END.    
		
		RETURN pbOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Skriver tekstlinje til loggfil.
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID SkrivTilLogg(INPUT cLoggfil AS CHARACTER,
	                                INPUT cTekst   AS CHARACTER ):

        DEFINE VARIABLE cDatoTid AS CHAR NO-UNDO.
        DEFINE VARIABLE cFilNavn AS CHAR NO-UNDO.
        DEFINE VARIABLE cKatalog AS CHAR NO-UNDO.

        cKatalog = '.\LOG'.
        IF cKatalog <> '' THEN 
        DO:
            /* Sikrer at katalog finnes. */
            OS-CREATE-DIR VALUE(RIGHT-TRIM(cKatalog,'\')).    
            cKatalog = RIGHT-TRIM(cKatalog,'\') + '\'.
        END.

        ASSIGN
            cFilNavn = cKatalog + cLoggfil + '.log'
            cDatoTid = STRING(TODAY) + ' ' + STRING(TIME,"HH:MM:SS") + ' '.

        OUTPUT STREAM Ut TO VALUE(cFilNavn) APPEND UNBUFFERED NO-ECHO.

        PUT STREAM Ut UNFORMATTED
            cDatoTid
            cTekst SKIP.

        OUTPUT STREAM Ut CLOSE.
		
		RETURN.

	END METHOD. /* SkrivTilLogg*/

	DESTRUCTOR PUBLIC StandardFunksjonerInfopos ( ):

	END DESTRUCTOR.

END CLASS.