#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'PARMTYPE.CH'
/*/{Protheus.doc} FINA010
Ponto de Entrada em MVC no Cadastro de Naturezas (FINA010)
@type function
@version  
@author Joalisson Laurentino
@since 26/09/2024
@return variant, return_description
/*/
User Function FINA010()


	Local _lRet       := .T.
	Local oModel        := ParamIXB[1]
	Local _cIdPonto   := ParamIXB[2]
	Local _cIdModel   := ParamIXB[3]
	Local _aArea   := GetArea()
	Local IS_INSERT   := oModel:GetOperation() == 3
	Local IS_UPDATE   := oModel:GetOperation() == 4


	If _cIdPonto == 'MODELPRE' /* Chamada antes da altera��o de qualquer campo do modelo. */

	ElseIf _cIdPonto == 'MODELPOS' /* Chamada na valida��o total do modelo. */

	ElseIf _cIdPonto == 'FORMPRE' /* Chamada na antes da altera��o de qualquer campo do formul�rio. */

	ElseIf _cIdPonto == 'FORMPOS' /* Chamada na valida��o total do formul�rio. */

	ElseIf _cIdPonto == 'FORMLINEPRE' /* Chamada na pre valida��o da linha do formul�rio. */

	ElseIf _cIdPonto == 'FORMLINEPOS' /* Chamada na valida��o da linha do formul�rio. */

	ElseIf _cIdPonto == 'MODELVLDACTIVE' /* Chamada na valida��o da ativa��o do Modelo. */

	ElseIf _cIdPonto == 'MODELCOMMITTTS' /* Chamada apos a grava��o total do modelo e dentro da transa��o. */

	ElseIf _cIdPonto == 'MODELCOMMITNTTS' /* Chamada apos a grava��o total do modelo e fora da transa��o. */

		if IS_INSERT .OR. IS_UPDATE
			SED->(RecLock("SED",.F.))
			SED->ED_ZONERGY := .T.
			SED->ED_ZINTOGY := '1'
			SED->(MsUnlock())
		Endif

	ElseIf _cIdPonto == 'FORMCOMMITTTSPRE' /* Chamada antes da grava��o da tabela do formul�rio. */

	ElseIf _cIdPonto == 'FORMCOMMITTTSPOS' /* Chamada apos a grava��o da tabela do formul�rio. */

	ElseIf _cIdPonto == 'MODELCANCEL' /* Cancela */

	ElseIf _cIdPonto == 'BUTTONBAR' /* Usado para Cria��o de Botoes Estrutura: { {'Nome', 'Imagem Botap', { || bBlock } } } */

	EndIf

	RestArea(_aArea)

Return _lRet
