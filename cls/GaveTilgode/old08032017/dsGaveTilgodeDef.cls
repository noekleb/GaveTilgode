 
 /*------------------------------------------------------------------------
    File        : tmpTblGaveTilgode
    Purpose     : 
    Syntax      : 
    Description : Inneholder temp tabell definisjon for postering i GaveTilgode.
    Author(s)   : tny
    Created     : Sun May 15 08:03:44 CEST 2016
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.


CLASS cls.GaveTilgode.dsGaveTilgodeDef:
    DEFINE VARIABLE bOk AS LOG NO-UNDO.

    /* Temp-table definisjon */
    {cls\GaveTilgode\tmpGaveTilgode.i}

    /* Dataset definisjon */
    {cls\GaveTilgode\dsGaveTilgode.i}
    
    /* Definerer query pr. hoved tabell i datasettet. */
    DEFINE QUERY qGaveTilgodeHode  FOR GaveTilgodeHode.

    /* Definerer Data-source for hver tabell.                             */
    /* NB: Legg merke til forskjellen på de to data-source definisjonene. */
    /*     Den første går mot en query, den andre rett mot tabellen.      */
    DEFINE DATA-SOURCE srcGaveTilgodeHode FOR QUERY qGaveTilgodeHode
        GaveTilgodeHode KEYS(ButNr, OrdreId).
    DEFINE DATA-SOURCE srcGaveTilgodeLinje FOR GaveTilgodeLinje
        KEYS(ButNr, OrdreId, LnNO).
    
    CONSTRUCTOR dsGaveTilgodeDef():
        CURRENT-WINDOW:WIDTH = 350.

        /*filldsGaveTilgode(11003, '').*/
        /*visGavetilgode().*/
        
    END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL filldsGaveTilgode( INPUT piButNr AS INTEGER,
	                                         INPUT pcWhere AS CHARACTER ):
		
		DEFINE VARIABLE pbOk AS LOGICAL NO-UNDO.

        /* Klagjør Query. */
        QUERY qGaveTilgodeHode:QUERY-PREPARE("FOR EACH GaveTilgodeHode WHERE GaveTilgodeHode.ButNr = '" + STRING(piButNr) + "' ").
    
        /* Kobler på datasource før fylling av datasett. */
        BUFFER tmpGavetilgodeHode:ATTACH-DATA-SOURCE (DATA-SOURCE srcGaveTilgodeHode:HANDLE). 
        BUFFER tmpGavetilgodeLinje:ATTACH-DATA-SOURCE (DATA-SOURCE srcGaveTilgodeLinje:HANDLE). 
        
        DATASET dsGaveTilgode:FILL().
        
        /* Kobler av datasource etter at datasettet er fyllt. */
        BUFFER tmpGavetilgodeHode:DETACH-DATA-SOURCE (). 
        BUFFER tmpGavetilgodeLinje:DETACH-DATA-SOURCE (). 

		RETURN pbOk.

	END METHOD.    

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC VOID visGavetilgode(  ):
		
        /* Bruker/viser frem data fra datasettet */
        FOR EACH tmpGaveTilgodeHode:
            DISPLAY
                tmpGaveTilgodeHode.ButNr FORMAT "->>>>>>>>9"
                tmpGaveTilgodeHode.OrdreId FORMAT "->>>>>>>>9"
                tmpGaveTilgodeHode.MotRef FORMAT "->>>>>>>>9"
                tmpGaveTilgodeHode.Sum FORMAT "->>>>>>>>>>>>>>>>9"
                tmpGaveTilgodeHode.DatoOpprettet FORMAT "99/99/99"
                tmpGaveTilgodeHode.DatoEndret FORMAT "99/99/99"
                tmpGaveTilgodeHode.OAv FORMAT "x(10)"
                tmpGaveTilgodeHode.EAv FORMAT "x(10)"
                tmpGaveTilgodeHode.BehStatus FORMAT "->>>>>>>>9"
                tmpGaveTilgodeHode.DatoSendt FORMAT "99/99/99"
                tmpGaveTilgodeHode.TblSeqNr FORMAT "->>>>>>>>>>>>>>>>9"
                WITH WIDTH 350.
            FOR EACH tmpGaveTilgodeLinje WHERE 
                tmpGaveTilgodeLinje.ButNr   = tmpGavetilgodeHode.butNr AND
                tmpGaveTilgodeLinje.OrdreId = tmpGavetilgodeHode.OrdreId:
                DISPLAY
                    tmpGaveTilgodeLinje.ButNr FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.OrdreId FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.LnNO FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.IdentNr FORMAT "x(20)"
                    tmpGaveTilgodeLinje.DatoTid FORMAT "99/99/99"
                    tmpGaveTilgodeLinje.Tid FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.KasseNr FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.KassNr FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.BongNr FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.FrabutNr FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.Belop FORMAT "->>>>>>>>>>>>>>>9.99"
                    tmpGaveTilgodeLinje.BruktDato FORMAT "99/99/99"
                    tmpGaveTilgodeLinje.BruktTid FORMAT "->>>>>>>>9"
                    tmpGaveTilgodeLinje.Transtype FORMAT "->>>>>>>>9"
                    WITH WIDTH 350.
            END.
        END.
		
		RETURN.

	END METHOD.
    
    DESTRUCTOR PUBLIC dsGaveTilgodeDef ( ):

    END DESTRUCTOR.
	

END CLASS.