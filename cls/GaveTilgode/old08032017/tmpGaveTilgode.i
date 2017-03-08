
/* Temp-table definisjon */
DEFINE TEMP-TABLE tmpGavetilgodeHode NO-UNDO BEFORE-TABLE beforeGavetilgodeHode
    FIELD BehStatus     AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD ButNr         AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD DatoEndret    AS DATE
    FIELD DatoOpprettet AS DATE
    FIELD DatoSendt     AS DATE
    FIELD EAv           AS CHARACTER   FORMAT "x(10)"
    FIELD MotRef        AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD Notat         AS CHARACTER   FORMAT "x(40)"
    FIELD OAv           AS CHARACTER   FORMAT "x(10)"
    FIELD OrdreId       AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD Sum           AS DECIMAL     DECIMALS 2 FORMAT "->>>>>>>>>>>>>>>>9"
    FIELD TblSeqNr      AS DECIMAL     DECIMALS 2 FORMAT "->>>>>>>>>>>>>>>>9"
INDEX idx_ButNrDatoSendtOrdreId OrdreId ButNr DatoSendt
INDEX Idx_ButOrdre IS UNIQUE ButNr OrdreId
INDEX idx_DatoEndret Datoendret
INDEX idx_DatoOpprettet DatoOpprettet
INDEX Idx_OrdreId OrdreId    
INDEX PK_GaveTilgodeHode IS UNIQUE TblSeqNr 
.

DEFINE TEMP-TABLE tmpGavetilgodelinje NO-UNDO BEFORE-TABLE beforeGaveTilgodeLinje
    FIELD Belopp        AS DECIMAL     DECIMALS 2 FORMAT "->>>>>>>>>>>>>>>9.99"
    FIELD BongNr        AS INTEGER     FORMAT "->>>>>>>9"
    FIELD BruktDato     AS DATE
    FIELD BruktTid      AS INTEGER     FORMAT "->>>>>>>9"
    FIELD ButNr         AS INTEGER     FORMAT "->>>>>>>9"
    FIELD DatoEndret    AS DATE
    FIELD DatoOpprettet AS DATE
    FIELD DatoTid       AS DATE
    FIELD DebKred       AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD FraButNr      AS INTEGER     FORMAT "->>>>>>>9"
    FIELD IdentNr       AS CHARACTER   FORMAT "x(20)"
    FIELD KasseNr       AS INTEGER     FORMAT "->>>>>>>9"
    FIELD KassNr        AS INTEGER     FORMAT "->>>>>>>9"
    FIELD LnNO          AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD OrdreId       AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD SekvensNr     AS INTEGER     FORMAT ">>9" LABEL "Sekvensnr"
    FIELD TblSeqNr      AS DECIMAL     DECIMALS 2 FORMAT "->>>>>>>>>>>>>>>>9"
    FIELD Tid           AS INTEGER     FORMAT "->>>>>>>9"
    FIELD Transtype     AS INTEGER     FORMAT "->>>>>>>>9"
INDEX icx_LesOgEksporter IS PRIMARY ButNr OrdreId Transtype DebKred    
INDEX idx_DatoEndret DatoEndret
INDEX idx_DatoOpprettet DatoOpprettet
INDEX idx_RefGavetOgtilgode TransType ButNr IdentNr SekvensNr DebKred
INDEX idx_SettesVedEksport ButNr OrdreId LnNo
.

DEFINE TEMP-TABLE tmpgavetogtilgode NO-UNDO BEFORE-TABLE beforegavetogtilgode
    FIELD BehStatus      AS INTEGER     FORMAT ">9" LABEL "Beh.status"
    FIELD belop          AS DECIMAL     DECIMALS 2 FORMAT "->>,>>>,>>9.99" LABEL "Belop" COLUMN-LABEL "Belop"
    FIELD bongnr         AS INTEGER     FORMAT ">>>>>>>9" LABEL "Bongnr" COLUMN-LABEL "Bongnr"
    FIELD bruktdato      AS DATE        FORMAT "99-99-99" LABEL "Bruktdato" COLUMN-LABEL "Bruktdato"
    FIELD brukttid       AS INTEGER     FORMAT ">>>>9" LABEL "Tid" COLUMN-LABEL "Tid"
    FIELD butnr          AS INTEGER     FORMAT ">>>>9" LABEL "Butnr" COLUMN-LABEL "Butnr"
    FIELD dato           AS DATE        FORMAT "99-99-99" INITIAL TODAY LABEL "Dato" COLUMN-LABEL "Dato"
    FIELD DatoEndret     AS DATETIME    FORMAT "99/99/9999 HH:MM:SS.SSS" INITIAL ? LABEL "Dato endret"
    FIELD DatoOpprettet  AS DATETIME    FORMAT "99/99/9999 HH:MM:SS.SSS" INITIAL ? LABEL "Dato opprettet"
    FIELD DatoSendt      AS DATETIME    FORMAT "99/99/9999 HH:MM:SS.SSS" INITIAL ? LABEL "Dato sendt"
    FIELD EAv            AS CHARACTER   FORMAT "X(8)" LABEL "Edret av"
    FIELD frabutnr       AS INTEGER     FORMAT ">>>>9" LABEL "Frabutnr" COLUMN-LABEL "Frabutnr"
    FIELD gyldigdato     AS DATE        FORMAT "99-99-99" LABEL "Gyldigdato" COLUMN-LABEL "Gyldigdato"
    FIELD identnr        AS CHARACTER   FORMAT "X(20)" LABEL "Identnr" COLUMN-LABEL "Identnr"
    FIELD identtype      AS INTEGER     FORMAT ">>>9" LABEL "Identtype" COLUMN-LABEL "Identtype"
    FIELD kassenr        AS INTEGER     FORMAT ">9" LABEL "Kassenr" COLUMN-LABEL "Kassenr"
    FIELD kassnr         AS INTEGER     FORMAT ">>>>>>>>9" LABEL "Kassnr" COLUMN-LABEL "Kassnr"
    FIELD modus          AS INTEGER     FORMAT "9" LABEL "Modus" COLUMN-LABEL "Modus"
    FIELD Notat          AS CHARACTER   FORMAT "x(30)" LABEL "Notat"
    FIELD OAv            AS CHARACTER   FORMAT "X(8)" LABEL "Opprettet av"
    FIELD OrdreIdSkyldig AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD OrdreIdTilgode AS INTEGER     FORMAT "->>>>>>>>9"
    FIELD sekvensnr      AS INTEGER     FORMAT ">>9" LABEL "Sekvensnr" COLUMN-LABEL "Sekvensnr"
    FIELD tid            AS INTEGER     FORMAT ">>>>9" LABEL "Tid" COLUMN-LABEL "Tid"
    FIELD TransType      AS INTEGER     FORMAT "9"
INDEX UnikIdx IS UNIQUE Transtype ButNr IdentNr SekvensNr    
.
