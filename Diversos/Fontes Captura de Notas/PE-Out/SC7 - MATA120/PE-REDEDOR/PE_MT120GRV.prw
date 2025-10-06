#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} MT120GRV
Continuar ou n�o a inclus�o, altera��o ou exclus�o - https://tdn.totvs.com/pages/releaseview.action?pageId=6085786
Par�metros:
ParamIXB[1] => cPedido - N�mero do pedido.										
ParamIXB[2] => lInclui - Controla a inclus�o.										
ParamIXB[3] => lAltera - Controla a altera��o.										
ParamIXB[4] => lExclui - Controla a exclus�o.
@author Joalisson Laurentino
@since 02/07/2023
@version 1.0
@type function
/*/
User Function MT120GRV()
	Local cPedido := ParamIXB[1]
	Local lInclui := ParamIXB[2]
	Local lAltera := ParamIXB[3]
	Local lExclui := ParamIXB[4]
	Local lRet    := .T.

	//Campos utilizados para integra��o com Taxfy - KTGroup
	If SC7->(FieldPos("C7_ZONERGY")) > 0 .AND. SC7->(FieldPos("C7_ZINTOGY")) > 0
		lRet    := .T.
	Endif

Return lRet
