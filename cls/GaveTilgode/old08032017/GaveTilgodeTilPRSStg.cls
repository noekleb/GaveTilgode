 
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
    DEFINE VARIABLE bOk                        AS LOG                      NO-UNDO.
    DEFINE VARIABLE iButNr                     AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE iLoop                      AS INTEGER                  NO-UNDO.
    DEFINE VARIABLE dDato                      AS DATE                     NO-UNDO.
    DEFINE VARIABLE dStartDato                 AS DATE NO-UNDO.
    DEFINE VARIABLE dSluttDato                 AS DATE NO-UNDO.
    DEFINE VARIABLE iX                         AS INTEGER NO-UNDO.
    DEFINE VARIABLE cTxt                       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFilNavn                   AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cKatalog                   AS CHARACTER                NO-UNDO.   
    DEFINE VARIABLE cFilPrefix                 AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cFilSufix                  AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE bTest                      AS LOG                      NO-UNDO.

    /* For eksport av data til JSon file. for TEST */
    DEFINE VARIABLE cTargetType AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFile      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lWriteOk   AS LOG       NO-UNDO.
    DEFINE VARIABLE lFormatted AS LOG       NO-UNDO.

    DEFINE VARIABLE rStandardFunksjoner AS cls.StdFunk.StandardFunksjonerInfopos NO-UNDO.

    /* Temp-table definisjon */
    {cls\GaveTilgode\tmpGaveTilgode.i}

    /* Dataset definisjon */
    {cls\GaveTilgode\dsGaveTilgode.i}
		
    DEFINE BUFFER bufGaveTilgodeLinje FOR tmpGaveTilgodeLinje.
    DEFINE BUFFER bufGaveTilgodeHode  FOR tmpGavetilgodeHode. 
        
    DEFINE STREAM Ut.

	CONSTRUCTOR PUBLIC GaveTilgodeTilPRSStg ( INPUT pdDato AS DATE ):
		SUPER ().	

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


        rStandardFunksjoner = NEW cls.StdFunk.StandardFunksjonerInfopos() NO-ERROR.

        ASSIGN
            bTest      = FALSE  
            cSkipLst   = ''
            cButLst    = ''
            cLogg      = 'GaveTilgodeTilPRSStg' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
            cKatalog   = 'konv\sendes\'
            cFilPrefix = 'tmpordre'
            cFilSufix  = '.txt'
            .
		
        /* TEST */
        IF SEARCH('tnc.txt') <> ? THEN 
            /*cButLst    = '11001,11003,11167,11359,11365,11367,11551'*/
            cButLst    = ''
            .

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start OppdaterGavetOgtilgode.'
            ). 
				
        /* Kjører oppdatering. Leser alle gavekort og tilgodelapper inn i tmpGavetOgtilgode for alle butikker. */
        OppdGavetOgtilgode().
                
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start GaveTilgodePrep.'
            ). 
                
        /* Oppdaterer datasett. Skaper tmpGavetilgodeHode og linje. */
        PrepGaveTilgode().
        
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start Eksporter.'
            ). 

        /* Setter ordrenr, og eksporterer data til csv/Excel fil. */
        Eksporter().

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig GaveTilgodeTilPRSStg.'
            ). 
        
        
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID Eksporter(  ):
    
    DEFINE VARIABLE piLnNo    AS INTEGER NO-UNDO.
    DEFINE VARIABLE piOrdreId AS INTEGER NO-UNDO.

        /* Henter filnavn */
        cFilNavn = EksporterhentFilnavn(0).

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


            /* Setter ordreId på ordrehode. */
            FIND FIRST tmpGavetilgodeHode WHERE 
                tmpGavetilgodeHode.butNr   = iButNr AND 
                tmpGavetilgodeHode.OrdreId = ? NO-ERROR.
            
            piLnNO = 0.
               
            IF AVAILABLE tmpGaveTilgodeHode THEN 
            DO:
                /* Finner ordreId */
                FIND LAST bufGaveTilgodeHode NO-LOCK WHERE             
                    bufGavetilgodeHode.OrdreId <> ? 
                    USE-INDEX Idx_OrdreId NO-ERROR. 
                IF AVAILABLE bufGavetilgodeHode THEN 
                    piOrdreId = bufGavetilgodeHode.OrdreId + 1.
                ELSE 
                    piOrdreId = 1.
            
                ASSIGN 
                    tmpGavetilgodeHode.OrdreId   = piOrdreId
                    tmpGaveTilgodeHode.DatoSendt = dDato
                    .
                    
                /* Setter linjenr på linjene. */
                FOR EACH tmpGavetilgodeLinje WHERE 
                    tmpGaveTilgodeLinje.butNr = iButNr AND
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
                END. 
            END.

            eksporterData(iButNr, cFilNavn).          

        END. /* BUTLOOP */

        /* Gjør rename på fil når den er ferdig lagt ut. */
        IF SEARCH(cFilNavn) <> ? THEN
            OS-COMMAND SILENT VALUE("MOVE " + cFilNavn + " " + REPLACE(REPLACE(cFilNavn,'tmpOrdre','Ordre'),'.txt','.edi')).

        RETURN.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL EksporterData( INPUT piButNr AS INTEGER,
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
                /* Ord.CSOrdNo */ ENTRY( 3,pcHode,';') = (IF tmpGaveTilgodeHode.OrdreId <> ? THEN 
                                                              STRING(tmpGaveTilgodeHode.OrdreId)
                                                              ELSE '?')
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
                    /* OrdLn.ProdNo   */ ENTRY( 3,pcLinje,';')  = '10004'
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
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID PrepGaveTilgode(  ):
		
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start.'
            ). 

        IF cButLst <> '' THEN
        BUTLOOP: 
        DO iLoop = 1 TO NUM-ENTRIES(cButLst):
            iButNr = INT(ENTRY(iLoop,cButLst)).

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Behandler butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer andres gavekort som er brukt i min butikker (Tilgode penger) */
            PrepPoster(iButNr, 1, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall gavekort brukt i min butikk oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer andres tilgodelapper som er brukt i min butikker (Tilgode penger) */
            PrepPoster(iButNr, 2, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall tilgodelapper brukt i min butikk oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer nye egne gavekort (Avgift 1%) */
            PrepPosterNyeGavekort(iButNr, 1, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall nye gavekort utstedt i min butikk ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

        END. /* BUTLOOP */

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig.'
            ). 
        
        
        /* detta skriver till fil på log katalog under arbeidskatalog. */
        IF bTest THEN 
        DO:
            ASSIGN  
                cTargetType = "file" 
                lFormatted  = TRUE 
            lWriteOK = DATASET dsGaveTilgode:WRITE-JSON(cTargetType, 'log\dsGaveTilgode.json', lFormatted).
        END.
        
        RETURN.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC CHARACTER EksporterhentFilnavn( INPUT piButNr AS INTEGER  ):
		
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

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdGavekort( INPUT  iValgtBut AS INTEGER,
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
            Gavekort.FraButNr   = iValgtBut:
                  
            ASSIGN 
                iButNr  = gavekort.ButNr
                i2butNr = gavekort.FrabutNr
                .      
                  
            /* Retter opp feil butikknr. */
            iButNr  = rStandardFunksjoner:RetterOppFeilButikknr(iButNr).
            i2ButNr = rStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND FIRST tmpGavetOgTilgode NO-LOCK WHERE 
                tmpGavetOgTilgode.Transtype = 1 AND 
                tmpGavetOgTilgode.ButNr     = iButNr AND 
                tmpGavetOgTilgode.IdentNr   = GaveKort.IdentNr AND 
                tmpGavetOgTilgode.SekvensNr = GaveKort.SekvensNr NO-ERROR.
            
            IF NOT AVAILABLE tmpGavetOgTilgode THEN 
            DO:
                CREATE tmpGavetOgTilgode.
                BUFFER-COPY Gavekort
                    EXCEPT ButNr FrabutNr 
                    TO tmpGavetOgTilgode 
                    ASSIGN 
                    tmpGavetOgTilgode.TransType = 1
                    tmpGavetOgTilgode.ButNr     = iButNr
                    tmpGavetOgTilgode.FrabutNr  = i2ButNr
                    .
                iAnt = iAnt + 1.
            END. 
            ELSE IF AVAILABLE tmpGavetOgTilgode THEN 
                DO:
                    BUFFER-COPY Gavekort
                        EXCEPT butNr FrabutNr  
                        TO tmpGavetOgTilgode
                        ASSIGN 
                        tmpGavetOgTilgode.ButNr     = iButNr
                        tmpGavetOgTilgode.FrabutNr  = i2ButNr
                        . 
                    iAnt = iAnt + 1.
                END.
        END. /* GAVELOOP */
        
        RETURN bOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID OppdGavetOgtilgode(  ):
        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Start.'
            ). 

        /* Sjekker at databasene er oppkoblet. Avbryter hvis de ikke er det.  */
        bOk = rStandardFunksjoner:SjekkOmDbErOppkoblet('infopos,PRSStg', 
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

        IF cButLst <> '' THEN
        BUTLOOP: 
        DO iLoop = 1 TO NUM-ENTRIES(cbutLst):
            iButNr = INT(ENTRY(iLoop,cButLst)).
    
            /* Oppdaterer TILGODE */
            OppdTilgode(iButNr, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall tilgode oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).
    
            /* Oppdaterer brukte GAVEKORT. */
            OppdGavekort(iButNr, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall gavekort oppdatert: ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Oppdaterer nye GAVEKORT. */
            OppdNyeGavekort(iButNr, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall nye gavekort oppdatert: ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).
        END. /* BUTLOOP */

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig.'
            ). 
		
        /* detta skriver till fil på log katalog under arbeidskatalog. */
        IF bTest THEN 
        DO:
            ASSIGN  
                cTargetType = "file" 
                lFormatted  = TRUE 
            lWriteOK = TEMP-TABLE tmpGaveTOgTilgode:WRITE-JSON(cTargetType, 'log\GavetOgTilgode.json', lFormatted).
        END.

		RETURN.
	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdNyeGavekort( INPUT  iValgtBut AS INTEGER,
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
            iButNr  = rStandardFunksjoner:RetterOppFeilButikknr(iButNr).
            i2ButNr = rStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND FIRST tmpGavetOgTilgode NO-LOCK WHERE 
                tmpGavetOgTilgode.Transtype = 1 AND 
                tmpGavetOgTilgode.ButNr     = iButNr AND 
                tmpGavetOgTilgode.IdentNr   = GaveKort.IdentNr AND 
                tmpGavetOgTilgode.SekvensNr = GaveKort.SekvensNr NO-ERROR.
            
            IF NOT AVAILABLE tmpGavetOgTilgode THEN 
            DO:
                CREATE tmpGavetOgTilgode.
                BUFFER-COPY Gavekort
                    EXCEPT ButNr FrabutNr 
                    TO tmpGavetOgTilgode 
                    ASSIGN 
                    tmpGavetOgTilgode.TransType = 1
                    tmpGavetOgTilgode.ButNr     = iButNr
                    tmpGavetOgTilgode.FrabutNr  = i2ButNr
                    .
                iAnt = iAnt + 1.
            END. /* TRANSACTION */
        END. /* GAVELOOP */
        
        RETURN bOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL OppdTilgode( INPUT  iValgtBut AS INTEGER, 
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
            Tilgode.ButNr      = iValgtBut: 

            ASSIGN 
                iButNr  = Tilgode.ButNr
                i2butNr = Tilgode.FrabutNr
                .      
                  
            /* Retter opp feil butikknr. */
            iButNr  = rStandardFunksjoner:RetterOppFeilButikknr(ibutNr).
            i2ButNr = rStandardFunksjoner:RetterOppFeilButikknr(i2butNr).
         
            FIND FIRST tmpGavetOgTilgode WHERE 
                tmpGavetOgTilgode.Transtype = 2 AND 
                tmpGavetOgTilgode.ButNr     = iButNr AND 
                tmpGavetOgTilgode.IdentNr   = Tilgode.IdentNr AND 
                tmpGavetOgTilgode.SekvensNr = 0 NO-ERROR.
            
            IF NOT AVAILABLE tmpGavetOgTilgode THEN 
            DO:
                CREATE tmpGavetOgTilgode.
                BUFFER-COPY Tilgode
                    EXCEPT ButNr FrabutNr
                    TO tmpGavetOgTilgode 
                    ASSIGN 
                    tmpGavetOgTilgode.TransType = 2
                    tmpGavetOgTilgode.butNr     = iButNr
                    tmpGavetOgTilgode.FraButNr  = i2ButNr
                    tmpGavetOgTilgode.SekvensNr = 0
                    .
                iAnt = iAnt + 1.
            END. /* TRANSACTION */
            ELSE IF AVAILABLE tmpGavetOgTilgode THEN 
                DO:
                    BUFFER-COPY Tilgode
                        EXCEPT butNr FrabutNr    
                        TO tmpGavetOgTilgode
                        ASSIGN 
                        tmpGavetOgTilgode.butNr     = iButNr
                        tmpGavetOgTilgode.FraButNr  = i2ButNr
                        .
                    iAnt = iAnt + 1.
                END.
        END. /* TILGODELOOP */

        RETURN bOk.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID OppdOpprettHode( piButNr AS INTEGER,
                                   OUTPUT lTblSeqNr AS DECIMAL ):
		
        DO:
            /* Flyller på hvis det finnes fra før. */
            FIND tmpGavetilgodeHode EXCLUSIVE-LOCK WHERE 
                tmpGavetilgodeHode.ButNr   = pibutNr AND 
                tmpGavetilgodeHode.OrdreId = ? AND 
                DATE(tmpGavetilgodeHode.DatoOpprettet) = TODAY NO-ERROR.
            IF NOT AVAILABLE tmpGavetilgodeHode THEN 
            DO:
                /* Setter TblSeqNr */
                FIND LAST tmpGaveTilgodeHode NO-LOCK USE-INDEX PK_GaveTilgodeHode NO-ERROR. 
                IF AVAILABLE tmpGavetilgodeHode THEN 
                    lTblSeqNr = tmpGavetilgodeHode.TblSeqNr + 1.
                ELSE 
                    lTblSeqNr = 1.         

                rStandardFunksjoner:SkrivTilLogg(cLogg,
                    '    Oppretter hode ButNr/TblSeqNr ' + STRING(iButNr) + ' / ' + STRING(lTblSeqNr) 
                    ).
            
                
                CREATE tmpGaveTilgodeHode.
                ASSIGN
                    tmpGaveTilgodeHode.ButNr         = pibutNr
                    tmpGavetilgodeHode.OrdreId       = ?
                    tmpGaveTilgodeHode.TblSeqNr      = lTblSeqNr
                    tmpGavetilgodeHode.Sum           = 0 /* Oppdateres ved gjennomlesning av alle linjene. */
                    tmpGaveTilgodeHode.DatoOpprettet = NOW
                    tmpGavetilgodeHode.DatoEndret    = NOW
                    tmpGaveTilgodeHode.OAv           = USERID('PRSStg')
                    tmpGaveTilgodeHode.BehStatus     = 1
                    tmpGaveTilgodeHode.Notat         = '' /* Oppdateres når linjene gjennomleses. */
                NO-ERROR.
                IF ERROR-STATUS:ERROR THEN 
                DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                    cTxt = '** GaveTilgodeHode - Opprett hode: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                    rStandardFunksjoner:SkrivTilLogg(cLogg,
                        '    ' + cTxt 
                        ).
                END.            
            END.
            ASSIGN 
                tmpGaveTilgodeHode.DatoEndret    = NOW
                tmpGaveTilgodeHode.EAv           = USERID('PRSStg')
                lTblSeqNr                        = tmpGaveTilgodeHode.TblSeqNr
                NO-ERROR.                
            IF ERROR-STATUS:ERROR THEN 
            DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                cTxt = '** GaveTilgodeHode - setter endret dato: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                rStandardFunksjoner:SkrivTilLogg(cLogg,
                    '    ' + cTxt 
                    ).
            END.            
        END. 
        
        RETURN.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL PrepPoster( piButNr AS INTEGER,
                                  piType AS INTEGER,
                                  OUTPUT piAnt AS INTEGER ):
		
        DEFINE VARIABLE result AS LOGICAL NO-UNDO.
        DEFINE VARIABLE piAntAvgift AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
        DEFINE VARIABLE lTblSeqNr AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
        DEFINE VARIABLE lMotTblSeqNr AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
        
        TILGODE:
        FOR EACH tmpGavetOgTilgode EXCLUSIVE-LOCK WHERE 
            tmpGavetOgTilgode.frabutnr  = piButNr AND 
            tmpGavetOgTilgode.TransType = pitype AND 
            tmpGavetOgTilgode.DatoSendt = ? AND 
            tmpGavetOgTilgode.bruktdato >= dStartDato AND 
            tmpGavetOgTilgode.bruktdato <= dSluttDato
            BREAK BY tmpGavetOgTilgode.frabutnr
                  BY tmpGavetOgTilgode.BruktDato:

            ASSIGN 
                /* Flagger posten som lest */
                tmpGavetOgTilgode.DatoSendt = NOW
                .

            DOBLOKKEN:
            DO: 
                   
                /* Nye og brukte gavekort skal posteres. Ubrukte tilgodelapper skal ignoreres. */  
                IF tmpGavetOgTilgode.bruktdato = ? THEN 
                    LEAVE DOBLOKKEN.
                
                /* Gave og tilgode brukt i egen butikk, skal ikke krediteres. */    
                IF tmpGavetOgtilgode.FrabutNr = tmpGavetOgtilgode.ButNr THEN
                    LEAVE DOBLOKKEN.                

                /* Forekommer i dataene. Egne papirbaserte gavekort som ikke skal behandles. */
                IF tmpGavetOgtilgode.FrabutNr = 0 THEN
                    LEAVE DOBLOKKEN.                

                /* Oppretter ordrehode hvis det ikke finnes fra før. */
                IF lTblSeqNr = 0 OR NOT CAN-FIND(FIRST tmpGavetilgodeHode WHERE 
                    tmpGavetilgodeHode.ButNr   = pibutNr AND 
                    tmpGavetilgodeHode.OrdreId = ? AND 
                    DATE(tmpGavetilgodeHode.DatoOpprettet) = TODAY) THEN
                    OppdOpprettHode(iButNr, OUTPUT lTblSeqNr).
                /* Henter hode slik at vi kan sette inn relasjonen på linjen. */                
                FIND FIRST tmpGavetilgodeHode NO-LOCK WHERE 
                    tmpGavetilgodeHode.TblSeqNr = lTblSeqNr NO-ERROR. 

                ASSIGN
                    piAnt = piAnt + 1
                    .
                
                FIND tmpGaveTilgodeLinje EXCLUSIVE-LOCK WHERE 
                    tmpGaveTilgodeLinje.Transtype = tmpGavetOgTilgode.TransType AND 
                    tmpGaveTilgodeLinje.ButNr     = piButNr AND 
                    tmpGaveTilgodeLinje.IdentNr   = tmpGavetOgTilgode.identnr AND 
                    tmpGaveTilgodeLinje.SekvensNr = tmpGavetOgTilgode.sekvensnr AND 
                    tmpGaveTilgodeLinje.DebKred   = 1 AND 
                    tmpGaveTilgodeLinje.FraButNr  = tmpGavetOgTilgode.butnr NO-ERROR.    
               
                /* Posterer kredit på den butikk som skal ha penger. ----- */
                IF NOT AVAILABLE tmpGaveTilgodeLinje THEN
                OPPSTANDELSEN: 
                DO:
                    CREATE tmpGaveTilgodeLinje.
                    ASSIGN 
                        piAntAvgift                    = piAntAvgift + 1
                        tmpGaveTilgodeLinje.TransType     = tmpGavetOgTilgode.TransType
                        tmpGaveTilgodeLinje.ButNr         = piButNr
                        tmpGaveTilgodeLinje.IdentNr       = tmpGavetOgTilgode.IdentNr 
                        tmpGaveTilgodeLinje.SekvensNr     = tmpGavetOgTilgode.SekvensNr          
                        tmpGaveTilgodeLinje.DebKred       = 1
                        tmpGaveTilgodeLinje.FrabutNr      = tmpGavetOgTilgode.ButNr

                        tmpGaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                        tmpGaveTilgodeLinje.OrdreId       = ? /* Settes ved utskrift når hode er opprettet. */
                        tmpGaveTilgodeLinje.LnNo          = 0
                        tmpGavetilgodeLinje.DatoTid       = DATETIME(tmpGavetOgTilgode.Dato, tmpGavetOgTilgode.tid * 1000) 
                        tmpGaveTilgodeLinje.Tid           = tmpGavetOgTilgode.Tid
                        tmpGaveTilgodeLinje.KasseNr       = tmpGavetOgTilgode.KasseNr
                        tmpGaveTilgodeLinje.KassNr        = tmpGavetOgTilgode.KassNr
                        tmpGaveTilgodeLinje.BongNr        = tmpGavetOgTilgode.BongNr
                        tmpGaveTilgodeLinje.Belop         = tmpGavetOgTilgode.belop * -1
                        tmpGavetilgodeLinje.BruktDato     = tmpGavetOgTilgode.bruktdato
                        tmpGaveTilgodeLinje.BruktTid      = tmpGavetOgTilgode.BruktTid
                        tmpGaveTilgodeLinje.DatoOpprettet = NOW
                        tmpGaveTilgodeLinje.DatoEndret    = NOW
                    NO-ERROR.
                    IF ERROR-STATUS:ERROR THEN 
                    DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                        cTxt = '** GaveTilgodeLinje(Poster Kred) - FeilNr: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                        rStandardFunksjoner:SkrivTilLogg(cLogg,
                            '    ' + cTxt 
                            ).
                    END.            
                
                    /* Nye Gavekort skal ikke motposteres. */
                    IF tmpGavetOgTilgode.bruktdato <> ? THEN 
                    MOTPOSTERING: 
                    DO:
                        /* Posterer debit på den butikk som skal betale ------- */
                        /* Oppretter ordrehode hvis det ikke finnes fra før.    */
                        /* Finnes det fra før, fylles det bare på.              */
                        IF NOT CAN-FIND(FIRST tmpGavetilgodeHode WHERE 
                            tmpGavetilgodeHode.ButNr   = tmpGavetOgTilgode.ButNr AND 
                            tmpGavetilgodeHode.OrdreId = ? AND 
                            DATE(tmpGavetilgodeHode.DatoOpprettet) = dDato) THEN 
                            OppdOpprettHode(tmpGavetOgTilgode.ButNr, OUTPUT lMotTblSeqNr).
                        /* Henter hode slik at vi kan sette inn relasjonen på linjen. */
                        FIND FIRST tmpGavetilgodeHode NO-LOCK WHERE 
                            tmpGavetilgodeHode.TblSeqNr = lMotTblSeqNr NO-ERROR. 
            
                        CREATE bufGaveTilgodeLinje.
                        BUFFER-COPY tmpGaveTilgodeLinje
                            EXCEPT ButNr FraBut Belop DebKred TblSeqNr
                            TO bufGaveTilgodeLinje
                            ASSIGN 
                            bufGaveTilgodelinje.TblSeqNr = lMotTblSeqNr
                            bufGaveTilgodeLinje.ButNr    = tmpGavetOgTilgode.ButNr
                            bufGaveTilgodeLinje.FraBut   = tmpGavetOgTilgode.FraBut
                            bufGaveTilgodeLinje.Belop    = ABS(tmpGavetOgTilgode.belop)
                            bufGaveTilgodelinje.DebKred  = 2 
                        NO-ERROR.
                        IF ERROR-STATUS:ERROR THEN 
                        DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                            cTxt = '** GaveTilgodeLinje(Poster Deb) - FeilNr: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                            rStandardFunksjoner:SkrivTilLogg(cLogg,
                                '    ' + cTxt 
                                ).
                        END.            
                    END. /* MOTPOSTERING */        
                
                END. /* OPPSTANDELSEN */    

            END. /* DOBLOKKEN */

            /* Avgiften skal belastes butikken hvor kortet brukes. */
            IF LAST-OF(tmpGavetOgTilgode.frabutnr) AND piantAvgift > 0 THEN 
            AVGIFT:
            DO:
                CREATE tmpGaveTilgodeLinje.
                ASSIGN 
                    tmpGaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                    tmpGaveTilgodeLinje.ButNr         = piButNr
                    tmpGaveTilgodeLinje.DebKred       = 1
                    tmpGaveTilgodeLinje.OrdreId       = ? /* Settes når hode er opprettet. */
                    tmpGaveTilgodeLinje.LnNo          = 0
                    tmpGaveTilgodeLinje.TransType     = IF pitype = 1 THEN 3 ELSE 4
                    tmpGaveTilgodeLinje.FrabutNr      = 0
                    tmpGaveTilgodeLinje.IdentNr       = '' 
                    tmpGaveTilgodeLinje.SekvensNr     = tmpGavetOgTilgode.SekvensNr          
                    tmpGavetilgodeLinje.DatoTid       = NOW 
                    tmpGaveTilgodeLinje.Tid           = TIME
                    tmpGaveTilgodeLinje.KasseNr       = 0
                    tmpGaveTilgodeLinje.KassNr        = 0
                    tmpGaveTilgodeLinje.BongNr        = 0
                    tmpGaveTilgodeLinje.Belop         = 10 * piantAvgift
                    tmpGavetilgodeLinje.BruktDato     = ?
                    tmpGaveTilgodeLinje.BruktTid      = 0
                    tmpGaveTilgodeLinje.DatoOpprettet = NOW
                    tmpGaveTilgodeLinje.DatoEndret    = NOW
                    NO-ERROR.
                IF ERROR-STATUS:ERROR THEN 
                DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                    cTxt = '** GaveTilgodeLinje(Poster Avgift) - FeilNr: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                    rStandardFunksjoner:SkrivTilLogg(cLogg,
                        '    ' + cTxt 
                        ).
                END.            
            END. /* AVGIFT */   
            
        END. /* TILGODE */

        RETURN result.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID PrepPosterNyeGavekort( piButNr AS INTEGER,
                                          piType AS INTEGER,
                                          OUTPUT piAnt AS INTEGER ):
		
        DEFINE VARIABLE piAntAvgift AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
        DEFINE VARIABLE plAvgift    AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
        DEFINE VARIABLE lTblSeqNr   AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
        
        NYE_GAVEKORT:
        FOR EACH tmpGavetOgTilgode EXCLUSIVE-LOCK WHERE
            tmpGavetOgTilgode.butnr     = piButNr AND 
            tmpGavetOgTilgode.TransType = pitype AND /* Alltid = 1 */
            tmpGavetOgTilgode.Dato      >= dStartDato AND
            tmpGavetOgTilgode.Dato      <= dSluttDato  
            BREAK BY tmpGavetOgTilgode.butnr:

            /* Oppretter ordrehode hvis det ikke finnes fra før. */
            IF NOT CAN-FIND(FIRST tmpGavetilgodeHode WHERE 
                tmpGavetilgodeHode.ButNr   = pibutNr AND 
                tmpGavetilgodeHode.OrdreId = ? AND 
                DATE(tmpGavetilgodeHode.DatoOpprettet) = dDato) THEN
                OppdOpprettHode(iButNr, OUTPUT lTblSeqNr).

            ASSIGN 
                piAntAvgift              = piAntAvgift + 1
                plAvgift                 = plAvgift + tmpGavetOgTilgode.belop
                tmpGavetOgTilgode.DatoSendt = (IF tmpGavetOgTilgode.bruktdato = ? THEN NOW ELSE tmpGavetOgTilgode.DatoSendt) 
                .
        END. /* NYE_GAVEKORT */

        /* AVGIFT_NYE_GAVEKORT */
        IF piAntAvgift > 0 THEN 
        AVGIFT_NYE_GAVEKORT:
        DO:
            CREATE tmpGaveTilgodeLinje.
            ASSIGN 
                tmpGaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                tmpGaveTilgodeLinje.ButNr         = piButNr
                tmpGaveTilgodeLinje.DebKred       = 1
                tmpGaveTilgodeLinje.OrdreId       = ? /* Settes når hode er opprettet. */
                tmpGaveTilgodeLinje.LnNo          = 0
                tmpGaveTilgodeLinje.TransType     = 7 /* Avgift nye Gavekort. */
                tmpGaveTilgodeLinje.FrabutNr      = 0
                tmpGaveTilgodeLinje.IdentNr       = '' 
                tmpGaveTilgodeLinje.SekvensNr     = tmpGavetOgTilgode.SekvensNr          
                tmpGavetilgodeLinje.DatoTid       = NOW 
                tmpGaveTilgodeLinje.Tid           = TIME
                tmpGaveTilgodeLinje.KasseNr       = 0
                tmpGaveTilgodeLinje.KassNr        = plAvgift
                tmpGaveTilgodeLinje.BongNr        = piAntAvgift
                tmpGaveTilgodeLinje.Belop         = ROUND(((plAvgift * 1) / 100),0)
                tmpGavetilgodeLinje.BruktDato     = ?
                tmpGaveTilgodeLinje.BruktTid      = 0
                tmpGaveTilgodeLinje.DatoOpprettet = NOW
                tmpGaveTilgodeLinje.DatoEndret    = NOW
                    NO-ERROR.
            IF ERROR-STATUS:ERROR THEN 
            DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                cTxt = '** GaveTilgodeLinje(Poster Avgift Nye Gavekort) - FeilNr: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                rStandardFunksjoner:SkrivTilLogg(cLogg,
                    '    ' + cTxt 
                    ).
            END.            
        END. /* AVGIFT_NYE_GAVEKORT */   
        
        RETURN.

	END METHOD.

	DESTRUCTOR PUBLIC GaveTilgodeTilPRSStg ( ):

	END DESTRUCTOR.

END CLASS.