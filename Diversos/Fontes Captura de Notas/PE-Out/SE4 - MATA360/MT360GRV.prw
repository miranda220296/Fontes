#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} MT360GRV
Descri��o:
Este ponto de entrada � executado apos a atualiza��o de todas as tabelas da rotina de condi��o de pagamento nas opera��es de inclus�o, altera��o e exclus�o.

Eventos

@author 
@since 
@version 1.0
@type function
/*/
User Function MT360GRV()

	Local aArea 	:= GetArea()

	//Campos utilizados para integra��o com Taxfy - KTGroup
	If SE4->(FieldPos("E4_ZONERGY")) > 0 .AND. SE4->(FieldPos("E4_ZINTOGY")) > 0
		If Inclui
			RecLock("SE4",.F.)
				M->E4_ZONERGY := .T.	//Habilita registro para integra��o
				M->E4_ZINTOGY := "1"	//1-Pendente | 2- Integrado | 3- Erro
			SE4->(MsUnlock())
		ElseIf Altera
			RecLock("SE4",.F.)
				SE4->E4_ZONERGY := .T.	//Habilita registro para integra��o
				SE4->E4_ZINTOGY := "1"	//1-Pendente | 2- Integrado | 3- Erro
			SE4->(MsUnlock())
		EndIf
	Else 
		FWAlertError("Condi��o de pagamento n�o ser� integrada ao Taxfy. Campos E4_ZONERGY e E4_ZINTOGY n�o foram criados. Rode o U_UPDKTG().","MT360GRV.prw - Taxfy - KTGroup")
	Endif

	RestArea(aArea)

Return 
