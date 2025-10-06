#Include 'TOTVS.ch'

/*/{Protheus.doc} User Function FA100VLD
    Validação do cancelamento/exclusão da movimentação bancária
    /*/
User Function FA100VLD()

	Local lExclui  :=  ParamIXB[1]
	Local lRet := .T.

	If lExclui
		U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)
	EndIf

Return lRet
