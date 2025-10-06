#include "totvs.ch"
#include "protheus.ch"
#include "topconn.ch"


/*/{Protheus.doc} F473CAGR
//Utilizado para gravação complementar no cancelamento da Efetivação da Conciliação Automática (FINA473).
/*/


User Function F473CAGR()
	Local nRecno
	Local _aArea := GetArea()
	Local _DtMov := SIG->IG_DTMOVI

	nRecno := PARAMIXB

	SE5->(DbGoto(nRecno))

	If Empty(_DtMov) .AND. !Empty(Alltrim(SE5->E5_XLOGMOV))
		U_MSLOGE5(2)//Chamada para gravar LOG de usuário na tabela SE5 (operação deleção)

	Else
		U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)

	EndIf


	RestArea(_aArea)
Return
