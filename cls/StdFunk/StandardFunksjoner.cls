 
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

CLASS cls.StdFunk.StandardFunksjoner: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    DEFINE STREAM Ut.
    DEFINE STREAM Inn.
    
    DEFINE VARIABLE cTekst AS CHARACTER NO-UNDO.

    { cls\StdFunk\filliste.i }
    
    DEFINE STREAM Inn.
    DEFINE STREAM Ut.
		
	CONSTRUCTOR PUBLIC StandardFunksjoner (  ):
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
            BUTLOOP:
            FOR EACH prsButiker NO-LOCK WHERE
                prsButiker.Butik > iButNrForste AND 
                prsButiker.Butik < iButNrSiste:
  
                /* Butikker som ikke skal være med i kontrollen. */
                IF CAN-DO(cSkipLst,STRING(prsButiker.Butik)) THEN 
                    NEXT BUTLOOP.
  
                /* Bygger liste over butikker som skal kontrolleres */
                IF NOT CAN-DO(cButlst,STRING(prsButiker.Butik)) THEN 
                    ASSIGN cButLst = cbutLst + ',' + STRING(prsButiker.Butik).  
            END. /* BUTLOOP */
            
            ASSIGN 
                cButLst = TRIM(cbutLst,',')
                bOk     = TRUE
                .
        END.

        RETURN bOk.

	END METHOD. /* HentListeAktiveButikker */

	/*------------------------------------------------------------------------------
	 Purpose: LagFillisteForKatalog
	           Lager en liste med filer. En record pr. fil, som ligger i angitt 
	           katalog. Et enkelt filter kan sendes inn. På fil prefix og suffix.
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID LagFillisteForKatalog( INPUT  cKatalog AS CHARACTER,
	                                          INPUT  cPrefixFilter AS CHARACTER, 
                                              INPUT  cExtentFilter AS CHARACTER, 
	                                          OUTPUT hFilListe AS HANDLE ):

        DEFINE VARIABLE cFilNavn    AS CHARACTER NO-UNDO.  
        DEFINE VARIABLE cFilePath   AS CHARACTER NO-UNDO.  
        DEFINE VARIABLE cFileAttrib AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lFilId      AS DECIMAL FORMAT ">>>>>>>>9" NO-UNDO.
		
        INPUT STREAM Inn FROM OS-DIR (cKatalog) NO-ECHO .
        
        FILINPUT:
        REPEAT:
            IMPORT STREAM Inn
                cFilNavn  
                cFilePath  
                cFileAttrib
                .

            /* Bare filer skal bahandles. */
            IF LOOKUP("F",cFileAttrib) <> 0 THEN
            FILBLOKK:
            DO:
                /* Åpner for filinformasjonen */
                ASSIGN
                    FILE-INFO:FILE-NAME = cFilePath
                    cTekst              = IF NUM-ENTRIES(cFilNavn,'.') > 1 THEN ENTRY(2,cFilNavn,'.') ELSE ''.
                . 
                /* Ignorerer tomme filer. */
                IF FILE-INFO:FILE-SIZE = 0 THEN 
                    NEXT FILINPUT.

                /* Kun filer med filnavn som oppfyller masken på filnavn skal inn. */
                IF cPrefixFilter <> '' THEN 
                DO:
                    IF NOT FILE-INFO:FILE-NAME MATCHES '*' + cPrefixFilter + '*' THEN 
                        NEXT FILINPUT.
                END.
                /* Kun filer med ekstent som oppfyller masken på extent skal inn. */
                IF cExtentFilter <> '' AND NUM-ENTRIES(FILE-INFO:FILE-NAME,'.') = 2 THEN 
                DO:
                    IF NOT ENTRY(2,FILE-INFO:FILE-NAME,'.') MATCHES '*' + cExtentFilter + '*' THEN 
                        NEXT FILINPUT.
                END.
      
                /* Sjekker at filen er mer enn 20 sec gammel. */
                IF FILE-INFO:FILE-MOD-DATE = TODAY THEN 
                DO:
                    IF TIME - FILE-INFO:FILE-MOD-TIME < 20 THEN 
                        NEXT FILINPUT.
                END. 

                /* Oppretter posten i filen. */
                IF NOT CAN-FIND(FIRST tmpFiler WHERE
                    tmpFiler.Full-Path-Name   = FILE-INFO:FILE-NAME AND
                    tmpFiler.File-Create-Date = FILE-INFO:FILE-CREATE-DATE AND
                    tmpFiler.File-Create-Time = FILE-INFO:FILE-CREATE-TIME AND
                    tmpFiler.File-Size        = FILE-INFO:FILE-SIZE AND
                    tmpFiler.PathName         = FILE-INFO:PATHNAME
                    ) THEN
                DO:
                    /* Finner FilId */
                    FIND LAST tmpFiler NO-LOCK NO-ERROR.
                    IF AVAILABLE tmpFiler THEN
                        lFilId = tmpFiler.FilId + 1.
                    ELSE
                        lFilId = 1.
                    CREATE tmpFiler.
                    ASSIGN
                        tmpFiler.FilId            = lFilId
                        tmpFiler.Full-Path-Name   = FILE-INFO:FILE-NAME 
                        tmpFiler.File-Create-Date = FILE-INFO:FILE-CREATE-DATE 
                        tmpFiler.File-Create-Time = FILE-INFO:FILE-CREATE-TIME 
                        tmpFiler.File-Size        = FILE-INFO:FILE-SIZE 
                        tmpFiler.PathName         = FILE-INFO:PATHNAME

                        tmpFiler.File-Mod-Date    = FILE-INFO:FILE-MOD-DATE 
                        tmpFiler.File-Mod-Time    = FILE-INFO:FILE-MOD-TIME 
                        tmpFiler.AntLinjer        = 0
                        tmpFiler.File-Type        = FILE-INFO:FILE-TYPE 
                        /*tmpFiler.cFile-Name        = cFilNavn*/
                        .
                END.

            END. /* FILBLOKK */
        END. /* FILINPUT */
        INPUT STREAM Inn CLOSE.
		
		
		RETURN.

	END METHOD. /* LagFillisteForKatalog */

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
                IF pcLogg <> '' AND pcLogg <> ? THEN  
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
            cDatoTid = STRING(TODAY) + ' ' + STRING(TIME,"HH:MM:SS") + ' '
            .

        OUTPUT STREAM Ut TO VALUE(cFilNavn) APPEND UNBUFFERED NO-ECHO.

        PUT STREAM Ut UNFORMATTED
            cDatoTid
            cTekst SKIP.

        OUTPUT STREAM Ut CLOSE.
		
		RETURN.

	END METHOD. /* SkrivTilLogg*/

	DESTRUCTOR PUBLIC StandardFunksjoner ( ):

	END DESTRUCTOR.

END CLASS.