#include "protheus.ch"

User Function F340SE5()
	Local aRecno := ParamIxb[1]
	Local nX := 0
	Local cMsg := ""
	Local aArea := getArea()

	SE5->(DbSetOrder(1))
	For nX  := 1 to Len(aRecno)
		SE5->(dbGoto(aRecno[nX ]))
		U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)
	Next nX

	RestArea(aArea)
Return
