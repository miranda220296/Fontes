#include "totvs.ch"

/* {Protheus.doc} FA100REC
Ponto de Entrada p/ grava��o da movimenta��o na rotina a Receber (Movimenta��o Banc�ria)
@type function
@author paulo.dias
@since 09/11/2021
@version 12.1.27
@project DOR09748161 
@return */

User Function FA100REC()

Local aAreaE5 := SE5->(GetArea())
Local cUsrAlt := UsrFullName(__cUserId)
 Conout("Entrou ponto de entrada FA100REC " + Time())

RecLock("SE5", .F. )
SE5->E5_XLOGMOV  := cUsrAlt
SE5->E5_XHORMOV  := TIME() 
SE5->E5_XDATMOV  := Date()
SE5->(MsUnlock())

RestArea(aAreaE5)
Conout("Saiu ponto de entrada FA100REC " + Time())
Return

