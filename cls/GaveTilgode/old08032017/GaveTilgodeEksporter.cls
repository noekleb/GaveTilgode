 
 /*------------------------------------------------------------------------
    File        : GaveTilgodeEksporter
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : tny
    Created     : Tue May 03 14:46:23 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING cls.*.

CLASS cls.Gavetilgode.GaveTilgodeEksporter: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
		
    DEFINE VARIABLE cLogg                      AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cButLst                    AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cSkipLst                   AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE iAnt                       AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE bOk                        AS LOG                      NO-UNDO.
    DEFINE VARIABLE iButNr                     AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE iLoop                      AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE cFilNavn                   AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cKatalog                   AS CHARACTER                NO-UNDO.   
    DEFINE VARIABLE cFilPrefix                 AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cFilSufix                  AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE bTest                      AS LOG                      NO-UNDO.
    DEFINE VARIABLE dDato                      AS DATE                     NO-UNDO.

    DEFINE VARIABLE rStandardFunksjoner AS cls.StdFunk.StandardFunksjoner NO-UNDO.
    
    /* Temp-table definisjon */
    {cls\GaveTilgode\tmpGaveTilgode.i}

    /* Dataset definisjon */
    {cls\GaveTilgode\dsGaveTilgode.i}
    
    /* Definerer query for hoved tabell i datasettet. */
    DEFINE QUERY qGaveTilgodeHode  FOR GaveTilgodeHode.

    /* Definerer Data-source for hver tabell.                             */
    /* NB: Legg merke til forskjellen på de to data-source definisjonene. */
    /*     Den første går mot en query, den andre rett mot tabellen.      */
    DEFINE DATA-SOURCE srcGaveTilgodeHode FOR QUERY qGaveTilgodeHode
        GaveTilgodeHode KEYS(ButNr, OrdreId).
        DEFINE DATA-SOURCE srcGaveTilgodeLinje FOR GaveTilgodeLinje
        KEYS(ButNr, OrdreId, LnNO).
   

    DEFINE STREAM Ut.

	CONSTRUCTOR PUBLIC GaveTilgodeEksporter ( INPUT pdDato AS DATE ):
        SUPER ().   

        rStandardFunksjoner = NEW cls.StdFunk.StandardFunksjoner() NO-ERROR.

        ASSIGN
            dDato      = pdDato 
            bTest      = TRUE 
            cSkipLst   = ''
            cButLst    = ''
            cLogg      = 'GaveTilgodeEksporter' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
            cKatalog   = 'konv\sendes\'
            cFilPrefix = 'tmpordre'
            cFilSufix  = '.txt'
            .
		
        /* TEST */
        /*
        IF SEARCH('tnc.txt') <> ? THEN
        DO: 
            /*cButLst    = '11001,11003,11167,11359,11365,11367,11551,11370'.*/
            cButLst    = '11023,11424,11235,11056,11019,11330'.
        END.
        */
        
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start CONSTRUCTOR startGaveTilgodeEksporter.'
            ). 

        /* Kjører oppdatering */
        Eksporter().

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig CONSTRUCTOR startGaveTilgodeEksporter.'
            ). 
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID Eksporter(  ):
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start.'
            ). 
        /* Sjekker at databasene er oppkoblet. Avbryter hvis de ikke er det.  */
        bOk = rStandardFunksjoner:SjekkOmDbErOppkoblet('sp1VB,PRSStg', 
            cLogg 
            ).
        IF NOT bOk THEN 
            RETURN.

        /* Henter liste over butikker det skal oppdateres gavekort og tilgode for. */
        rStandardFunksjoner:HentListeAktiveButikker(cSkipLst, 
            INPUT-OUTPUT cButLst
            ).
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Butikkliste: ' + cButLst + '.'
            ).

        /* Henter filnavn */
        cFilNavn = hentFilnavn(0).

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Eksportfil: ' + cFilnavn + '.'
            ).

        IF cButLst <> '' THEN
        BUTLOOP: 
        DO iLoop = 1 TO NUM-ENTRIES(cButLst):
            iButNr = INT(ENTRY(iLoop,cButLst)).

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Behandler butikk ' + STRING(iButNr) + '.'
                ).

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Tøm datasett ' + STRING(iButNr) + '.'
                ).
            /* Tøm datasett               */
            /* -------------------------- */
            DATASET dsGaveTilgode:EMPTY-DATASET ().

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Fyll datasett ' + STRING(iButNr) + '.'
                ).
                
            /* Fyller datasett.           */
            /* -------------------------- */
            filldsGaveTilgode(iButNr, '').
            
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Hent filnavn ' + STRING(iButNr) + '.'
                ).
            /* Henter filnavn */
            /*cFilNavn = hentFilnavn(iButNr).*/
            
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  EksporterData ' + STRING(iButNr) + '.'
                ).
                
            /* Eksporter data for butikk. */
            /* -------------------------- */
            eksporterData(iButNr, cFilNavn).          

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Loop ferdig ' + STRING(iButNr) + '.'
                ).

        END. /* BUTLOOP */

        /* Gjør rename på fil når den er ferdig lagt ut. */
        IF SEARCH(cFilNavn) <> ? THEN
            OS-COMMAND SILENT VALUE("MOVE " + cFilNavn + " " + REPLACE(REPLACE(cFilNavn,'tmpOrdre','Ordre'),'.txt','.edi')).

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig.'
            ). 
		
		RETURN.
	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL eksporterData( INPUT piButNr AS INTEGER,
	                                     INPUT pcFile  AS CHARACTER ):
		
        DEFINE VARIABLE pbOk AS LOG NO-UNDO.
        DEFINE VARIABLE pcFilNavn AS CHARACTER  NO-UNDO.   
        DEFINE VARIABLE piLnNo AS INTEGER NO-UNDO.     
        
        DEFINE VARIABLE pcHode AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pcLinje AS CHARACTER NO-UNDO. 
        DEFINE VARIABLE pcTekst AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pcSkille AS CHARACTER NO-UNDO.
        
        /* detta skriver till fil på log katalog under arbeidskatalog. */
        /* TEST
        DEFINE VARIABLE cTargetType AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cFile      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lWriteOk   AS LOG       NO-UNDO.
        DEFINE VARIABLE lFormatted AS LOG       NO-UNDO.
        ASSIGN  
            cTargetType = "file" 
            lFormatted  = TRUE 
        lWriteOK = DATASET dsGaveTilgode:WRITE-JSON(cTargetType, REPLACE(REPLACE(pcFile,'.csv','.json'),'OrdreNr_',''), lFormatted).
        */

        FOR EACH tmpGaveTilgodeHode WHERE 
        tmpGaveTilgodeHode.ButNr = pibutNr
            BREAK BY tmpGaveTilgodeHode.ButNr
                  BY tmpGavetilgodeHode.OrdreId:
                      
            ASSIGN 
                /*pcFilNavn = REPLACE(pcFile,'OrdreNr',STRING(tmpGavetilgodeHode.OrdreId))*/
                pcFilNavn = pcFile
                piLnNo    = 0
                .
            OUTPUT STREAM Ut TO VALUE(pcFilNavn) APPEND.
            
            /* Setter opp hodeStreng. */
            pcHode = FILL(';',80).
            
            ASSIGN 
                /* RecType     */ ENTRY( 1,pcHode,';') = 'H'
                /* Ord.CSOrdNo */ ENTRY( 3,pcHode,';') = STRING(tmpGaveTilgodeHode.OrdreId)
                /* Ord.OrdTp   */ ENTRY( 4,pcHode,';') = '2'     
                /* Ord.CustNo  */ ENTRY( 7,pcHode,';') = STRING(tmpGaveTilgodeHode.ButNr)
                /* Ord.OrdDt   */ ENTRY(23,pcHode,';') = STRING(YEAR(dDato),"9999") + STRING(MONTH(dDato),"99") + STRING(DAY(dDato),"99")
                /* Ord.Gr      */ ENTRY(70,pcHode,';') = '5'
                .
            
            PUT STREAM Ut UNFORMATTED 
                pcHode
                SKIP.

            FOR EACH tmpGaveTilgodeLinje WHERE 
                tmpGaveTilgodeLinje.ButNr   = tmpGavetilgodeHode.ButNr AND
                tmpGavetilgodeLinje.OrdreId = tmpGaveTilgodeHode.OrdreId AND
                tmpGavetilgodeLinje.Transtype > 0 AND 
                tmpGavetilgodeLinje.DebKred > 0
                BREAK BY tmpGaveTilgodeLinje.ButNr   
                      BY tmpGavetilgodeLinje.OrdreId 
                      BY tmpGavetilgodeLinje.Transtype
                      BY tmpGavetilgodeLinje.DebKred: 

                piLnNo = piLnNo + 1.
                 
                /* Skille record som forteller hva som kommer */
                IF FIRST-OF(tmpGavetilgodeLinje.DebKred) AND tmpGaveTilgodeLinje.Transtype < 3 THEN 
                SKILLE:
                DO:
                    /* Setter opp skillestreng. */
                    pcSkille = FILL(';',75).
                    ASSIGN        
                    /* RecType        */ ENTRY( 1,pcSkille,';')  = 'L'
                    /* OrdLn.LnNo     */ ENTRY( 2,pcSkille,';')  = STRING(piLnNo)
                    /* OrdLn.ProdNo   */ ENTRY( 3,pcSkille,';')  = '10003'
                    /* OrdLn.Descr    */ ENTRY( 4,pcSkille,';')  = CAPS( 
                                                                          (IF tmpGaveTilgodeLinje.Transtype = 1 
                                                                            THEN 'Gavekort - '
                                                                           ELSE 'Tilgodelapp'
                                                                          ) +
                                                                          (IF tmpGaveTilgodeLinje.DebKred = 1 
                                                                             THEN 'godtgjørelse fra utstedende butikk.'
                                                                           ELSE 'Betaling til mottagende butikk.')
                                                                        ) 
                    /* OrdLn.R4       */ ENTRY(52,pcSkille,';')  = STRING(tmpGaveTilgodeLinje.butNr)
                    .
                    PUT STREAM Ut UNFORMATTED 
                        pcSkille
                        SKIP.
                    piLnNo = piLnNo + 1.
                END. 

                /* Navn på butikk */
                FIND prsButiker NO-LOCK WHERE 
                    prsButiker.Butik = tmpGavetilgodeLinje.FraButNr NO-ERROR.
                IF AVAILABLE prsButiker THEN 
                    pcTekst = prsButiker.ButNamn.
                ELSE 
                    pcTekst = '* Ukjent butikk'.
                                   
                /* Setter opp linjeStreng. */
                pcLinje = FILL(';',75).                               
                
                /* Avgift */
                IF CAN-DO('3,4,7',STRING(tmpGaveTilgodeLinje.Transtype)) THEN 
                ASSIGN 
                        /* RecType        */ ENTRY( 1,pcLinje,';')  = 'L'
                        /* OrdLn.LnNo     */ ENTRY( 2,pcLinje,';')  = STRING(piLnNo)
                        /* OrdLn.ProdNo   */ ENTRY( 3,pcLinje,';')  = '10003'
                        /* OrdLn.Descr    */ ENTRY( 4,pcLinje,';')  = IF tmpGaveTilgodeLinje.Transtype = 3
                                                                          THEN 'Avgift Gavekort '
                                                                      ELSE IF tmpGaveTilgodeLinje.Transtype = 7
                                                                          THEN 'Avgift Nye Gavekort (' + STRING(tmpGaveTilgodeLinje.BongNr) + ' Stk. 1% av ' + STRING(tmpGaveTilgodeLinje.KassNr) + ')'
                                                                      ELSE 'Avgift Tilgodelapp'                                                                               
                        /* OrdLn.NoInvoAb */ ENTRY( 5,pcLinje,';')  = '1' /* Dette er antallet. */
                        /* OrdLn.Price    */ ENTRY( 6,pcLinje,';')  = REPLACE(TRIM(STRING(tmpGaveTilgodeLinje.Belop,"->>>>>>>>>>>>>>>9.99"),' '),',','.')
                        /* OrdLn.R4       */ ENTRY(52,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.butNr)
                        /* OrdLn.TrInf1   */ ENTRY(56,pcLinje,';')  = ''
                        /* OrdLn.TrInf2   */ ENTRY(57,pcLinje,';')  = ''
                        /* OrdLn.ProdPrGr */ ENTRY(61,pcLinje,';')  = ''

                        /* Ukjente felt legges sist (Før radstatus feltet) */
                        /* OrdLn.TrInf3   */ ENTRY(73,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.DatoTid,"99.99.9999")
                .
                
                /* Varelinje */
                ELSE 
                ASSIGN
                    /* RecType        */ ENTRY( 1,pcLinje,';')  = 'L'
                    /* OrdLn.LnNo     */ ENTRY( 2,pcLinje,';')  = STRING(piLnNo)
                    /* OrdLn.ProdNo   */ ENTRY( 3,pcLinje,';')  = '10002'
                    /* OrdLn.Descr    */ ENTRY( 4,pcLinje,';')  = (IF      tmpGaveTilgodeLinje.Transtype = 1 AND tmpGavetilgodeLinje.DebKred = 1 THEN 'Gavekort fra butikk '
                                                                   ELSE IF tmpGaveTilgodeLinje.Transtype = 1 AND tmpGavetilgodeLinje.DebKred = 2 THEN 'Gavekort brukt i butikk '
                                                                   ELSE IF tmpGaveTilgodeLinje.Transtype = 2 AND tmpGavetilgodeLinje.DebKred = 1 THEN 'Tilgodelapp fra butikk '
                                                                   ELSE 'Tilgodelapp brukt i butikk '
                                                                  ) +
                                                                  pcTekst + 
                                                                  '.'
                    /* OrdLn.NoInvoAb */ ENTRY( 5,pcLinje,';')  = '1' /* Dette er antallet. */
                    /* OrdLn.Price    */ ENTRY( 6,pcLinje,';')  = REPLACE(TRIM(STRING(tmpGaveTilgodeLinje.Belop,"->>>>>>>>>>>>>>>9.99"),' '),',','.')
                    /* OrdLn.R4       */ ENTRY(52,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.ButNr)
                    /* OrdLn.TrInf1   */ ENTRY(56,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.BongNr)
                    /* OrdLn.TrInf2   */ ENTRY(57,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.FrabutNr)
                    /* OrdLn.ProdPrGr */ ENTRY(61,pcLinje,';')  = '100'

                    /* Ukjente felt legges sist (Før radstatus feltet) */
                    /* OrdLn.TrInf3   */ ENTRY(73,pcLinje,';')  = STRING(tmpGaveTilgodeLinje.DatoTid,"99.99.9999")
                    /* OrdLn.TrInf4   */ ENTRY(74,pcLinje,';')  = (IF tmpGaveTilgodeLinje.BruktDato = ? 
                                                                       THEN '?'
                                                                       ELSE STRING(tmpGaveTilgodeLinje.BruktDato,"99.99.9999"))
                    /* TEST identnr   */ ENTRY(75,pcLinje,';')  = (IF BTest 
                                                                       THEN tmpGaveTilgodeLinje.IdentNr
                                                                       ELSE '')                                                   
                    .
                    
                PUT STREAM Ut UNFORMATTED 
                    pcLinje
                    SKIP.
            END.    
            
            OUTPUT STREAM Ut CLOSE.

        END.
        pbOK = TRUE.        

        RETURN pbOK. 		

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Leser 
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL filldsGaveTilgode( INPUT piButNr AS INTEGER,
                                             INPUT pcWhere AS CHARACTER ):
		
        DEFINE VARIABLE pbOk AS LOGICAL NO-UNDO.
        DEFINE VARIABLE piOrdreId AS INTEGER NO-UNDO.
        DEFINE VARIABLE piLnNO AS INTEGER NO-UNDO.
        
        DEFINE VARIABLE lFormatted  AS LOG       NO-UNDO.
        DEFINE VARIABLE cTargetType AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cJSonFile   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE lWriteOK    AS LOG       NO-UNDO.
         
        FIND FIRST GavetilgodeHode NO-LOCK WHERE 
            GavetilgodeHode.ButNr   = piButNr AND
            GavetilgodeHode.OrdreId = ? AND 
            DATE(GavetilgodeHode.DatoOpprettet) = dDato NO-ERROR.
        IF NOT AVAILABLE GavetilgodeHode THEN 
        DO:
            RETURN pbOk.
        END. 
         
        /* Klagjør Query. */        
        QUERY qGaveTilgodeHode:QUERY-PREPARE("FOR EACH GaveTilgodeHode WHERE GaveTilgodeHode.ButNr = '" + STRING(piButNr) + "' AND " +
                                                  "GaveTilgodeHode.OrdreId = '?' AND DATE(GaveTilgodeHode.DatoOpprettet) = " + STRING(dDato) + " ").
                                                  
        /* --- Dette kan kjøres for å få ut export av en avregning for en gitt dato. NB: Kommenter query ut linjen over når dette kjøres.
        QUERY qGaveTilgodeHode:QUERY-PREPARE("FOR EACH GaveTilgodeHode WHERE GaveTilgodeHode.ButNr = '" + STRING(piButNr) + "' AND " +
             " DATE(GaveTilgodeHode.DatoOpprettet) = DATE(12,1,2016)").
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Butikkliste: ' + "FOR EACH GaveTilgodeHode WHERE GaveTilgodeHode.ButNr = '" + STRING(piButNr) + "' AND " +
            " DATE(GaveTilgodeHode.DatoOpprettet) = DATE(12,1,2016)" + '.'
            ).    
        */

        /* Kobler på datasource før fylling av datasett. */
        BUFFER tmpGavetilgodeHode:ATTACH-DATA-SOURCE (DATA-SOURCE srcGaveTilgodeHode:HANDLE). 
        BUFFER tmpGavetilgodeLinje:ATTACH-DATA-SOURCE (DATA-SOURCE srcGaveTilgodeLinje:HANDLE). 
        
        /* Fyller tabellen */
        DATASET dsGaveTilgode:FILL().        
        
        /* detta skriver till fil */
        ASSIGN  
            lFormatted  = TRUE 
            cTargetType = "file" 
            cJSonFile   = "log\dsGaveTilgode" + STRING(piButNr) + ".json".
        lWriteOK = DATASET dsGaveTilgode:WRITE-JSON(cTargetType, cJSonFile, lFormatted).        
        
                
        /* Setter ordreId på ordrehode. */
        FIND FIRST tmpGavetilgodeHode WHERE 
            tmpGavetilgodeHode.butNr   = pibutNr AND 
            tmpGavetilgodeHode.OrdreId = ? NO-ERROR.
        
        piLnNO = 0.
           
        IF AVAILABLE tmpGaveTilgodeHode THEN 
        DO:
            /* Finner ordreId */
            FIND LAST GaveTilgodeHode NO-LOCK WHERE             
                GavetilgodeHode.OrdreId <> ? 
                USE-INDEX Idx_OrdreId NO-ERROR. 
            IF AVAILABLE GavetilgodeHode THEN 
                piOrdreId = GavetilgodeHode.OrdreId + 1.
            ELSE 
                piOrdreId = 1.
        
            /* Slår på tracking */
            TEMP-TABLE tmpGavetilgodeHode:TRACKING-CHANGES = TRUE.

            ASSIGN 
                tmpGavetilgodeHode.OrdreId   = piOrdreId
                tmpGaveTilgodeHode.DatoSendt = dDato
                .
                
            /* Setter linjenr på linjene. */
            FOR EACH tmpGavetilgodeLinje WHERE 
                tmpGaveTilgodeLinje.butNr = pibutNr AND
                tmpGavetilgodeLinje.OrdreId = ?
                BY tmpGaveTilgodeLinje.ButNr
                BY tmpGaveTilgodeLinje.OrdreId
                BY tmpGaveTilgodeLinje.Transtype
                BY tmpGaveTilgodeLinje.DebKred:
                
                piLnNO = piLnNO + 1.
                ASSIGN
                    tmpGaveTilgodeLinje.OrdreId = piOrdreId 
                    tmpGaveTilgodeLinje.LnNO    = piLnNo
                    .
                    
                /* Oppdaterer databasen her, da relasjonen er endret ved at ordreid er endret. */
                FIND FIRST GaveTilgodeLinje EXCLUSIVE-LOCK WHERE
                    GaveTilgodeLinje.ButNr     = tmpGaveTilgodeLinje.ButNr AND 
                    GaveTilgodeLinje.Transtype = tmpGaveTilgodeLinje.Transtype AND 
                    GaveTilgodeLinje.IdentNr   = tmpGaveTilgodeLinje.identNr AND 
                    GaveTilgodeLinje.SekvensNr = tmpGaveTilgodeLinje.SekvensNr AND 
                    GaveTilgodeLinje.DebKred   = tmpGaveTilgodeLinje.DebKred AND 
                    GaveTilgodeLinje.DatoTid   = dDato  
                    NO-ERROR.
                IF AVAILABLE GaveTilgodeLinje THEN 
                    ASSIGN 
                    GaveTilgodeLinje.OrdreId = piOrdreId
                    GaveTilgodeLinje.LnNO    = piLnNo
                    .
         
            END. 
            
            /* Slår av tracking */
            TEMP-TABLE tmpGavetilgodeHode:TRACKING-CHANGES = FALSE.
            
            /* Lagrer endrede poster. */
            IF BUFFER beforeGavetilgodeHode:AVAILABLE THEN 
                BUFFER beforeGavetilgodeHode:SAVE-ROW-CHANGES() NO-ERROR.        
        END.
            
        /* Kobler av datasource etter at datasettet er fyllt. */
        BUFFER tmpGavetilgodeHode:DETACH-DATA-SOURCE (). 
        BUFFER tmpGavetilgodeLinje:DETACH-DATA-SOURCE (). 

        RETURN pbOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC CHARACTER hentFilnavn( INPUT piButNr AS INTEGER ):
		
		DEFINE VARIABLE pcFilNavn AS CHARACTER NO-UNDO.
		
        /* Sikrer at butikkens katalog finnes. */
        OS-COMMAND SILENT VALUE('mkdir ' + RIGHT-TRIM(cKatalog,'\')).
        
        ASSIGN 
            pcFilNavn = cKatalog + 
                        cFilPrefix +
                        REPLACE(STRING(TODAY,"99/99/9999"),'/','') + 
                        '_' +
                        REPLACE(STRING(TIME,'HH:MM:SS'),':','') + 
                        cFilsufix
            . 
         
		RETURN pcFilNavn.

	END METHOD.

	DESTRUCTOR PUBLIC GaveTilgodeEksporter ( ):

	END DESTRUCTOR.

END CLASS.