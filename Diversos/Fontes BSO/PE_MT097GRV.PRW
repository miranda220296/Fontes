#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} MT097GRV()
Controla a gravação de alçadas nos processos de compras. Antes da gravação da tabela SCR.
@author     Paulo Krüger
@since      18/09/2017
@version    P12.7
@Project    MAN0000007423046
@Return     lRet
/*/

User Function MT097GRV()

	Local aArea := GetArea()
	Local aDocto   := PARAMIXB[1]
	Local dDataRef := PARAMIXB[2]
	Local nOper    := PARAMIXB[3]
	Local cDocSF1  := PARAMIXB[4]
	Local lResiduo := PARAMIXB[5]
	Local lRet  := .T.
	Local nRecCR := SCR->(RECNO())
	Local cNumCR := ""
	Local cFilCR := ""
	Local cTipoCr := ""

	lRet := U_F1200717(.T.) //Verifica se a medição de contrato vem de rotina customizada

	IF FindFunction("U_F1207504")
		If nOper == 2  //Transferência da Alçada para o Superior
			U_F1207504("A",aDocto,nOper) //Rotina para gravar o código do aprovador anterior.
		EndIf
	EndIf

	If FindFunction("U_RecNoSCR")
		U_RecNoSCR(SCR->(Recno()))
	EndIf

	If aDocto[2] == "RV" .And. lRet
		DbSelectArea(SCR)
		SCR->(DbSetOrder(1))
		SCR->(DbSeek(xFilial("SCR")+aDocto[2]+aDocto[1]))
		cFilCr := SCR->CR_FILIAL
		cTipoCr := SCR->CR_TIPO
		cNumCr :=  SCR->CR_NUM
		While AllTrim(SCR->(CR_FILIAL+CR_TIPO+CR_NUM)) == AllTrim(cFilCr+cTipoCR+cNumCr)
			fAtuSCS(SCR->CR_FILIAL,SCR->CR_APROV,SCR->CR_USER,dDatabase,SCR->CR_TOTAL,SCR->CR_MOEDA)
			SCR->(DbSkip())
		EndDo
	EndIf

	SCR->(DbGoto(nRecCR))
	RestArea(aArea)

Return lRet


Static Function fAtuSCS(cFilCr,cUsrAprov,cUsrCr,dDataLib,nValLib,nMoeda)

	Local aArea := GetArea()
	Local nSldMax := 0

	DbSelectArea("SCS")
	SCS->(DbSetOrder(1))

	If SCS->(DbSeek(cFilCr+cUsrCr+DtoS(dDataLib)))
		Reclock("SCS",.F.)
		SCS->CS_SALDO := SCS->CS_SALDO - nValLib
		SCS->(MsUnLock())
	Else

		nSldMax := Posicione("SAK", 01, FwXFilial("SAK") + cUsrAprov, "AK_LIMITE" )
		Reclock("SCS",.T.)
		SCS->CS_FILIAL := cFilCr
		SCS->CS_COD    := cUsrCr
		SCS->CS_APROV  := cUsrAprov
		SCS->CS_DATA   := dDataLib
		SCS->CS_MOEDA  := nMoeda
		SCS->CS_SALDO  := nSldMax - nValLib

		SCS->(MsUnLock())
	EndIf

	RestArea(aArea)
Return
