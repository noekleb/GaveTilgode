 
 /*------------------------------------------------------------------------
    File        : GaveTilgodeTilPRSStg
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : tny
    Created     : Tue May 03 14:46:23 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING cls.*.

CLASS cls.GaveTilgode.GaveTilgodeTilPRSStg: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
		
    DEFINE VARIABLE cLogg                      AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cButLst                    AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cSkipLst                   AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE iAnt                       AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE iAntDg                     AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE bOk                        AS LOG                      NO-UNDO.
    DEFINE VARIABLE iButNr                     AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE iLoop                      AS INTEGER                  NO-UNDO.

    DEFINE VARIABLE moStandardFunksjoner        AS cls.StdFunk.StandardFunksjonerInfopos NO-UNDO.
    DEFINE VARIABLE moOppdaterPRSStgFraInfopos  AS cls.GaveTilgode.OppdaterPRSStgFraInfopos NO-UNDO. 

    DEFINE BUFFER bufsp1BestArtikkel FOR sp1BestArtikkel.
		
	CONSTRUCTOR PUBLIC GaveTilgodeTilPRSStg (  ):
		SUPER ().	

        moStandardFunksjoner       = NEW cls.StdFunk.StandardFunksjonerInfopos() NO-ERROR.
        moOppdaterPRSStgFraInfopos = NEW cls.GaveTilgode.OppdaterPRSStgFraInfopos() NO-ERROR.

        ASSIGN
            iAntDg   = 40
            cSkipLst = ''
            cButLst  = ''
            cLogg    = 'GaveTilgodeTilPRSStg' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
            .
		
        /* TEST */
        IF SEARCH('tnc.txt') <> ? THEN 
            /*cButLst    = '11001,11003,11167,11359,11365,11367,11551'*/
            cButLst    = ''
            .
				
        /* Kjører oppdatering */
        OppdaterGavetOgtilgode().
        
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID OppdaterGavetOgtilgode(  ):
        moStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start.'
            ). 
        moStandardFunksjoner:SkrivTilLogg(cLogg,
            (IF iAntDg > 0 THEN  
            'Sjekker ' + STRING(iAntDg) + ' dager tilbake i tid.'
            ELSE 'Sjekker ALLE poster.')
            ). 

        /* Sjekker at databasene er oppkoblet. Avbryter hvis de ikke er det.  */
        bOk = moStandardFunksjoner:SjekkOmDbErOppkoblet('infopos,PRSStg', 
            cLogg 
            ).
        IF NOT bOk THEN 
            RETURN.

        /* Henter liste over butikker det skal oppdateres gavekort og tilgode for. */
        moStandardFunksjoner:HentListeAktiveButikker(cSkipLst, 
            INPUT-OUTPUT cButLst
            ).
        moStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Butikkliste: ' + cButLst + '.'
            ).

        IF cButLst <> '' THEN
        BUTLOOP: 
        DO iLoop = 1 TO NUM-ENTRIES(cbutLst):
            iButNr = INT(ENTRY(iLoop,cButLst)).
    
            /* Oppdaterer TILGODE */
            moOppdaterPRSStgFraInfopos:OppdaterTilgode(iButNr,
                iAntDg, 
                OUTPUT iAnt
                ).
            moStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall tilgode oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).
    
            /* Oppdaterer brukte GAVEKORT. */
            moOppdaterPRSStgFraInfopos:OppdaterGavekort(iButNr,
                iAntDg, 
                OUTPUT iAnt
                ).
            moStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall gavekort oppdatert: ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Oppdaterer nye GAVEKORT. */
            moOppdaterPRSStgFraInfopos:OppdaterNyeGavekort(iButNr,
                iAntDg, 
                OUTPUT iAnt
                ).
            moStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall nye gavekort oppdatert: ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).
        END. /* BUTLOOP */

        moStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig.'
            ). 
		
		RETURN.
	END METHOD.

	DESTRUCTOR PUBLIC GaveTilgodeTilPRSStg ( ):

	END DESTRUCTOR.

END CLASS.