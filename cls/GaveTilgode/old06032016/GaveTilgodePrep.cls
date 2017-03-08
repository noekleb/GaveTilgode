 
 /*------------------------------------------------------------------------
    File        : GaveTilgodePrep
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : tny
    Created     : Tue May 03 14:46:23 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING cls.*.

CLASS cls.GaveTilgode.GaveTilgodePrep: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
		
    DEFINE VARIABLE cLogg      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cButLst    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSkipLst   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iAnt       AS INTEGER   NO-UNDO.
    DEFINE VARIABLE bOk        AS LOG       NO-UNDO.
    DEFINE VARIABLE iButNr     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iLoop      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE lTblSeqNr  AS DECIMAL   NO-UNDO. 
    DEFINE VARIABLE iX         AS INTEGER   NO-UNDO.       
    DEFINE VARIABLE cTxt       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE dDato      AS DATE      NO-UNDO.
    DEFINE VARIABLE dStartDato AS DATE      NO-UNDO.
    DEFINE VARIABLE dSluttDato AS DATE      NO-UNDO.

    DEFINE VARIABLE rStandardFunksjoner           AS cls.StdFunk.StandardFunksjoner           NO-UNDO.

    DEFINE BUFFER bufGaveTilgodeLinje FOR GaveTilgodeLinje. 
    
	CONSTRUCTOR PUBLIC GaveTilgodePrep (  ):
		SUPER ().	

        rStandardFunksjoner = NEW cls.StdFunk.StandardFunksjoner() NO-ERROR.

        ASSIGN 
            dDato = TODAY 
            .
            
        /* Finner første dag i forrige måned. */
        IF MONTH(TODAY) > 1 THEN
                dStartDato = DATE(MONTH(TODAY) - 1,1,YEAR(TODAY)).
        ELSE 
            /* Eller første dag siste måned forrige år. */
            dStartDato = DATE(12,1,YEAR(TODAY) - 1).

        /* Finner siste dag i forrige måned. */
        dSluttDato = DATE(MONTH(TODAY),1,YEAR(TODAY)) - 1.            

        ASSIGN
            cSkipLst = ''
            cButLst  = ''
            cLogg    = 'GaveTilgodePrep' + REPLACE(STRING(TODAY,"99/99/9999"),'/','')
            .
		
        /* TEST */
        IF SEARCH('tnc.txt') <> ? THEN
        DO: 
            /*cButLst    = '11001,11003,11167,11359,11365,11367,11551,11370'.*/
            cButLst    = ''.
        END.
		
        /* Kjører oppdatering */
        OppdaterGavetTilgode().
        
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID OppdaterGavetTilgode(  ):
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

        IF cButLst <> '' THEN
        BUTLOOP: 
        DO iLoop = 1 TO NUM-ENTRIES(cButLst):
            iButNr = INT(ENTRY(iLoop,cButLst)).

            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '  Behandler butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer nye egne gavekort (Avgift 1%) */
            PosterNyeGavekort(iButNr, 1, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall nye gavekort utstedt i min butikk ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer andres gavekort som er brukt i min butikker (Tilgode penger) */
            Poster(iButNr, 1, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall gavekort brukt i min butikk oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).

            /* Posterer andres tilgodelapper som er brukt i min butikker (Tilgode penger) */
            Poster(iButNr, 2, OUTPUT iAnt).
            rStandardFunksjoner:SkrivTilLogg(cLogg,
                '    Antall tilgodelapper brukt i min butikk oppdatert ' + STRING(iAnt) + ' for butikk ' + STRING(iButNr) + '.'
                ).
    
        END. /* BUTLOOP */

        rStandardFunksjoner:SkrivTilLogg(cLogg, 
            'Ferdig.'
            ). 
		
		RETURN.
	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID OpprettHode(piButNr AS INTEGER,
	                               OUTPUT lTblSeqNr AS DECIMAL  
	                              ):
        DO TRANSACTION:
            /* Flyller på hvis det finnes fra før. */
            FIND GavetilgodeHode EXCLUSIVE-LOCK WHERE 
                GavetilgodeHode.ButNr   = pibutNr AND 
                GavetilgodeHode.OrdreId = ? AND 
                DATE(GavetilgodeHode.DatoOpprettet) = TODAY NO-ERROR.
            IF NOT AVAILABLE GavetilgodeHode THEN 
            DO:
                /* Setter TblSeqNr */
                FIND LAST GaveTilgodeHode NO-LOCK USE-INDEX PK_GaveTilgodeHode NO-ERROR. 
                IF AVAILABLE GavetilgodeHode THEN 
                    lTblSeqNr = GavetilgodeHode.TblSeqNr + 1.
                ELSE 
                    lTblSeqNr = 1.         

                rStandardFunksjoner:SkrivTilLogg(cLogg,
                    '    Oppretter hode ButNr/TblSeqNr ' + STRING(iButNr) + ' / ' + STRING(lTblSeqNr) 
                    ).
            
                
                CREATE GaveTilgodeHode.
                ASSIGN
                    GaveTilgodeHode.ButNr         = pibutNr
                    GavetilgodeHode.OrdreId       = ?
                    GaveTilgodeHode.TblSeqNr      = lTblSeqNr
                    GavetilgodeHode.Sum           = 0 /* Oppdateres ved gjennomlesning av alle linjene. */
                    GaveTilgodeHode.DatoOpprettet = NOW
                    GavetilgodeHode.DatoEndret    = NOW
                    GaveTilgodeHode.OAv           = USERID('PRSStg')
                    GaveTilgodeHode.BehStatus     = 1
                    GaveTilgodeHode.Notat         = '' /* Oppdateres når linjene gjennomleses. */
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
                GaveTilgodeHode.DatoEndret    = NOW
                GaveTilgodeHode.EAv           = USERID('PRSStg')
                lTblSeqNr                     = GaveTilgodeHode.TblSeqNr
                NO-ERROR.                
            IF ERROR-STATUS:ERROR THEN 
            DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                cTxt = '** GaveTilgodeHode - setter endret dato: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                rStandardFunksjoner:SkrivTilLogg(cLogg,
                    '    ' + cTxt 
                    ).
            END.            

            FIND CURRENT GavetilgodeHode NO-LOCK NO-ERROR.            
        END. /* TRANSACTION */
		
		RETURN.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Posterer gave og tilgode som andre har brukt i min butikk. 
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL Poster( piButNr AS INTEGER,
	                                     piType AS INTEGER,
	                                     OUTPUT piAnt AS INTEGER
	                                    ):
		
		DEFINE VARIABLE result AS LOGICAL NO-UNDO.
		DEFINE VARIABLE piAntAvgift AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
		DEFINE VARIABLE lTblSeqNr AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
        DEFINE VARIABLE lMotTblSeqNr AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
		
        TILGODE:
        FOR EACH GavetOgTilgode EXCLUSIVE-LOCK WHERE
            GavetOgTilgode.frabutnr  = piButNr AND 
            GavetOgTilgode.TransType = pitype AND 
            GavetOgTilgode.DatoSendt = ? AND 
            GavetOgTilgode.bruktdato >= dStartDato AND 
            GavetOgTilgode.bruktdato <= dSluttDato
            BREAK BY GavetOgTilgode.frabutnr:

            DOBLOKKEN:
            DO: 
                   
                /* Nye og brukte gavekort skal posteres. Ubrukte tilgodelapper skal ignoreres. */  
                IF GavetOgTilgode.bruktdato = ? THEN 
                    LEAVE DOBLOKKEN.
                
                /* TEST - Brukte før 1/6-16 skal ikke faktureres.
                IF SEARCH('tnc.txt') = ? AND GavetOgTilgode.bruktdato < 06/01/2016 THEN 
                    LEAVE DOBLOKKEN.
                */
                
                /* Gave og tilgode brukt i egen butikk, skal ikke krediteres. */    
                IF GavetOgtilgode.FrabutNr = GavetOgtilgode.ButNr THEN
                    LEAVE DOBLOKKEN.                

                /* Forekommer i dataene. Egne papirbaserte gavekort som ikke skal behandles. */
                IF GavetOgtilgode.FrabutNr = 0 THEN
                    LEAVE DOBLOKKEN.                

                /* Oppretter ordrehode hvis det ikke finnes fra før. */
                IF NOT CAN-FIND(FIRST GavetilgodeHode WHERE 
                    GavetilgodeHode.ButNr   = pibutNr AND 
                    GavetilgodeHode.OrdreId = ? AND 
                    DATE(GavetilgodeHode.DatoOpprettet) = TODAY) THEN
                    OpprettHode(iButNr, OUTPUT lTblSeqNr).
                /* Henter hode slik at vi kan sette inn relasjonen på linjen. */                
                FIND FIRST GavetilgodeHode NO-LOCK WHERE 
                    GavetilgodeHode.TblSeqNr = lTblSeqNr NO-ERROR. 

                ASSIGN
                    piAnt = piAnt + 1
                    .
                
                FIND GaveTilgodeLinje EXCLUSIVE-LOCK WHERE 
                    GaveTilgodeLinje.Transtype = GavetOgTilgode.TransType AND 
                    GaveTilgodeLinje.ButNr     = GavetOgTilgode.butnr AND 
                    GaveTilgodeLinje.IdentNr   = GavetOgTilgode.identnr AND 
                    GaveTilgodeLinje.SekvensNr = GavetOgTilgode.sekvensnr AND 
                    GaveTilgodeLinje.DebKred   = 1 NO-ERROR.    
               
                /* Posterer kredit på den butikk som skal ha penger. ----- */
                IF NOT AVAILABLE GaveTilgodeLinje THEN
                OPPSTANDELSEN: 
                DO:
                    CREATE GaveTilgodeLinje.
                    ASSIGN 
                        piAntAvgift                    = piAntAvgift + 1
                        GaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                        GaveTilgodeLinje.ButNr         = piButNr
                        GaveTilgodeLinje.DebKred       = 1
                        GaveTilgodeLinje.OrdreId       = ? /* Settes ved utskrift når hode er opprettet. */
                        GaveTilgodeLinje.LnNo          = 0
                        GaveTilgodeLinje.TransType     = GavetOgTilgode.TransType
                        GaveTilgodeLinje.FrabutNr      = GavetOgTilgode.ButNr
                        GaveTilgodeLinje.IdentNr       = GavetOgTilgode.IdentNr 
                        GaveTilgodeLinje.SekvensNr     = GavetOgTilgode.SekvensNr          
                        GavetilgodeLinje.DatoTid       = DATETIME(GavetOgTilgode.Dato, GavetOgTilgode.tid * 1000) 
                        GaveTilgodeLinje.Tid           = GavetOgTilgode.Tid
                        GaveTilgodeLinje.KasseNr       = GavetOgTilgode.KasseNr
                        GaveTilgodeLinje.KassNr        = GavetOgTilgode.KassNr
                        GaveTilgodeLinje.BongNr        = GavetOgTilgode.BongNr
                        GaveTilgodeLinje.Belop         = GavetOgTilgode.belop * -1
                        GavetilgodeLinje.BruktDato     = GavetOgTilgode.bruktdato
                        GaveTilgodeLinje.BruktTid      = GavetOgTilgode.BruktTid
                        GaveTilgodeLinje.DatoOpprettet = NOW
                        GaveTilgodeLinje.DatoEndret    = NOW
                    NO-ERROR.
                    IF ERROR-STATUS:ERROR THEN 
                    DO ix = 1 TO ERROR-STATUS:NUM-MESSAGES:        
                        cTxt = '** GaveTilgodeLinje(Poster Kred) - FeilNr: ' + STRING(ERROR-STATUS:GET-NUMBER(ix)) + ' ' + ERROR-STATUS:GET-MESSAGE(ix).      
                        rStandardFunksjoner:SkrivTilLogg(cLogg,
                            '    ' + cTxt 
                            ).
                    END.            
                
                    /* Nye Gavekort skal ikke motposteres. */
                    IF GavetOgTilgode.bruktdato <> ? THEN 
                    MOTPOSTERING: 
                    DO:
                        /* Posterer debit på den butikk som skal betale ------- */
                        /* Oppretter ordrehode hvis det ikke finnes fra før.    */
                        /* Finnes det fra før, fylles det bare på.              */
                        IF NOT CAN-FIND(FIRST GavetilgodeHode WHERE 
                            GavetilgodeHode.ButNr   = GavetOgTilgode.ButNr AND 
                            GavetilgodeHode.OrdreId = ? AND 
                            DATE(GavetilgodeHode.DatoOpprettet) = TODAY) THEN 
                            OpprettHode(GavetOgTilgode.ButNr, OUTPUT lMotTblSeqNr).
                        /* Henter hode slik at vi kan sette inn relasjonen på linjen. */
                        FIND FIRST GavetilgodeHode NO-LOCK WHERE 
                            GavetilgodeHode.TblSeqNr = lMotTblSeqNr NO-ERROR. 
            
                        CREATE bufGaveTilgodeLinje.
                        BUFFER-COPY GaveTilgodeLinje
                            EXCEPT ButNr FraBut Belop DebKred TblSeqNr
                            TO bufGaveTilgodeLinje
                            ASSIGN 
                            bufGaveTilgodelinje.TblSeqNr = lMotTblSeqNr
                            bufGaveTilgodeLinje.ButNr    = GavetOgTilgode.ButNr
                            bufGaveTilgodeLinje.FraBut   = GavetOgTilgode.FraBut
                            bufGaveTilgodeLinje.Belop    = ABS(GavetOgTilgode.belop)
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

                ASSIGN 
                    /* Flagger posten som lest */
                    GavetOgTilgode.DatoSendt = NOW
                    .
            END. /* DOBLOKKEN */

            /* Avgiften skal belastes butikken hvor kortet brukes. */
            IF LAST-OF(GavetOgTilgode.frabutnr) AND piantAvgift > 0 THEN 
            AVGIFT:
            DO:
                CREATE GaveTilgodeLinje.
                ASSIGN 
                    GaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                    GaveTilgodeLinje.ButNr         = piButNr
                    GaveTilgodeLinje.DebKred       = 1
                    GaveTilgodeLinje.OrdreId       = ? /* Settes når hode er opprettet. */
                    GaveTilgodeLinje.LnNo          = 0
                    GaveTilgodeLinje.TransType     = IF pitype = 1 THEN 3 ELSE 4
                    GaveTilgodeLinje.FrabutNr      = 0
                    GaveTilgodeLinje.IdentNr       = '' 
                    GaveTilgodeLinje.SekvensNr     = GavetOgTilgode.SekvensNr          
                    GavetilgodeLinje.DatoTid       = NOW 
                    GaveTilgodeLinje.Tid           = TIME
                    GaveTilgodeLinje.KasseNr       = 0
                    GaveTilgodeLinje.KassNr        = 0
                    GaveTilgodeLinje.BongNr        = 0
                    GaveTilgodeLinje.Belop         = 10 * piantAvgift
                    GavetilgodeLinje.BruktDato     = ?
                    GaveTilgodeLinje.BruktTid      = 0
                    GaveTilgodeLinje.DatoOpprettet = NOW
                    GaveTilgodeLinje.DatoEndret    = NOW
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

	METHOD PUBLIC VOID PosterNyeGavekort( piButNr AS INTEGER,
                                         piType AS INTEGER,
                                         OUTPUT piAnt AS INTEGER
                                         ):
		
        DEFINE VARIABLE piAntAvgift AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
        DEFINE VARIABLE plAvgift    AS DECIMAL FORMAT "->>>>>>9.99"NO-UNDO.
        DEFINE VARIABLE lTblSeqNr   AS DECIMAL FORMAT "->>>>>>>>>>>>>>>>9" NO-UNDO.
        
        NYE_GAVEKORT:
        FOR EACH GavetOgTilgode EXCLUSIVE-LOCK WHERE
            GavetOgTilgode.butnr     = piButNr AND 
            GavetOgTilgode.TransType = pitype AND /* Alltid = 1 */
            GavetOgTilgode.Dato      >= dStartDato AND
            GavetOgTilgode.Dato      <= dSluttDato  
            BREAK BY GavetOgTilgode.butnr:

            /* Oppretter ordrehode hvis det ikke finnes fra før. */
            IF NOT CAN-FIND(FIRST GavetilgodeHode WHERE 
                GavetilgodeHode.ButNr   = pibutNr AND 
                GavetilgodeHode.OrdreId = ? AND 
                DATE(GavetilgodeHode.DatoOpprettet) = TODAY) THEN
                OpprettHode(iButNr, OUTPUT lTblSeqNr).

            ASSIGN 
                piAntAvgift              = piAntAvgift + 1
                plAvgift                 = plAvgift + GavetOgTilgode.belop
                GavetOgTilgode.DatoSendt = NOW
                .
        END. /* NYE_GAVEKORT */

        /* AVGIFT_NYE_GAVEKORT */
        IF piAntAvgift > 0 THEN 
        AVGIFT_NYE_GAVEKORT:
        DO:
            CREATE GaveTilgodeLinje.
            ASSIGN 
                GaveTilgodeLinje.TblSeqNr      = lTblSeqNr
                GaveTilgodeLinje.ButNr         = piButNr
                GaveTilgodeLinje.DebKred       = 1
                GaveTilgodeLinje.OrdreId       = ? /* Settes når hode er opprettet. */
                GaveTilgodeLinje.LnNo          = 0
                GaveTilgodeLinje.TransType     = 7 /* Avgift nye Gavekort. */
                GaveTilgodeLinje.FrabutNr      = 0
                GaveTilgodeLinje.IdentNr       = '' 
                GaveTilgodeLinje.SekvensNr     = GavetOgTilgode.SekvensNr          
                GavetilgodeLinje.DatoTid       = NOW 
                GaveTilgodeLinje.Tid           = TIME
                GaveTilgodeLinje.KasseNr       = 0
                GaveTilgodeLinje.KassNr        = plAvgift
                GaveTilgodeLinje.BongNr        = piAntAvgift
                GaveTilgodeLinje.Belop         = ROUND(((plAvgift * 1) / 100),0)
                GavetilgodeLinje.BruktDato     = ?
                GaveTilgodeLinje.BruktTid      = 0
                GaveTilgodeLinje.DatoOpprettet = NOW
                GaveTilgodeLinje.DatoEndret    = NOW
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

	DESTRUCTOR PUBLIC GaveTilgodePrep ( ):

	END DESTRUCTOR.

END CLASS.