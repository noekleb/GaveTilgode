DEF VAR mcButLst  AS CHAR NO-UNDO.
DEF VAR mcSkipLst AS CHAR NO-UNDO.
DEF VAR mbOk      AS LOG  NO-UNDO.

DEF VAR moStandardFunksjoner AS cls.StandardFunksjoner NO-UNDO.

ASSIGN 
    mcButLst  = ''
    mcSkipLst = '11412'
    .

/* Starter opp og gjør tilgjengelig. */
moStandardFunksjoner = NEW cls.StandardFunksjoner().

mbOk = moStandardFunksjoner:HentListeAktiveButikker(INPUT mcSkipLst, INPUT-OUTPUT mcButLst).

MESSAGE 
    'mcButLst:' mcButLst SKIP
    'mbOk:' mbOk
    VIEW-AS ALERT-BOX INFO BUTTONS OK.
