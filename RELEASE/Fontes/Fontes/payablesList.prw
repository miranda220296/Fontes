// #########################################################################################
// Projeto: Monkey
// Modulo : SIGAFIN
// Fonte  : payablesList
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------
// 30/04/21 | Rafael Yera Barchi| Solicita rela��o de t�tulos a pagar para dispon�veis para 
//          |                   | negocia��o
// ---------+-------------------+-----------------------------------------------------------

#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} payablesList
Solicita rela��o de t�tulos a pagar para dispon�veis para negocia��o

@author    Rafael Yera Barchi
@version   1.xx
@since     30/04/2021
/*/
//------------------------------------------------------------------------------------------
WSRESTFUL payablesList DESCRIPTION "ATOS DATA payablesList - Lista de T�tulos"

	WSDATA 		cResponse   AS STRING

	WSMETHOD 	POST 		DESCRIPTION "Solicita rela��o de t�tulos a pagar para dispon�veis para negocia��o" WSSYNTAX "/payablesList"

END WSRESTFUL



//------------------------------------------------------------------------------------------
/*/{Protheus.doc} payablesList
payablesList - M�todo POST

@author    Rafael Yera Barchi
@version   1.xx
@since     30/04/2021

Exemplo de Requisi��o: 
//--- In�cio
null
//--- Fim

/*/
//------------------------------------------------------------------------------------------
WSMETHOD POST WSSERVICE payablesList

	Local 	lReturn     := .T.
	Local 	lCheckAuth  := SuperGetMV("MK_CHKAUTH", , .F.)
	Local 	lUltimo		:= .F.
	Local 	aTabEmp		:= {}
	Local 	aEmpFil		:= {}
	Local 	cMNKLote	:= ""
	Local	cMessage 	:= ""
	Local 	cResponse 	:= ""
	Local 	nE 			:= 0
	Local 	nEmps		:= 0
	Local 	nHTTPCode 	:= 400
	Local   cLogDir		:= SuperGetMV("MK_LOGDIR", , "\log\")
	Local   cLogArq		:= "payablesList"
	Local cVarMK_INTMNK:= SuperGetMV("MK_INTMNK", , .F.)
	

	ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList In�cio"))
	FWLogMsg("INFO", , "MONKEY", "payablesList", "001", "001", "In�cio do Processo", 0, 0, {})
	
	::SetContentType("application/JSON;charset=UTF-8")

	If lCheckAuth
		cUser := U_MNKRetUsr(::GetHeader("Authorization"))
	Else
		ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList Executando sem autentica��o"))
		FWLogMsg("WARN", , "MONKEY", "payablesList", "002", "400", "In�cio do Processo", 0, 0, {})
	EndIf

	If lCheckAuth .And. Empty(cUser)

		lReturn		:= .F.
		nHTTPCode 	:= 401
		cMessage 	:= "Usu�rio n�o autenticado"

	Else

        ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList GetSXENum In�cio"))
		cMNKLote 	:= GetSXENum("ZM1", "ZM1_COD")
		ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList GetSXENum Fim"))
		ZM1->(DBSelectArea("ZM1"))
        ZM1->(DBSetOrder(1))
		If !ZM1->(DBSeek(FWxFilial("ZM1") + cMNKLote))
			ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList Grava��o do Lote ZM1 In�cio"))
			RecLock("ZM1", .T.)
				ZM1->ZM1_FILIAL	:= FWxFilial("ZM1")
				ZM1->ZM1_COD 	:= cMNKLote
				ZM1->ZM1_DATA 	:= Date()
				ZM1->ZM1_STATUS	:= "1"
			ZM1->(MSUnLock())
			ConfirmSX8()
			ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList Grava��o do Lote ZM1 Fim"))
		Else
			lReturn 	:= .F.
			nHTTPCode 	:= 500
			cMessage 	:= "Lote j� existente"
			RollBackSX8()
		EndIf

		If lReturn

			SM0->(DBSelectArea("SM0"))
			SM0->(DBGoTop())
			While !SM0->(EOF())
				
				ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | Registro SM0: " + SM0->M0_CODIGO + "/" + SM0->M0_CODFIL))
				
				If AScan(aTabEmp, RetSQLName("SE2")) == 0
					
					AAdd(aTabEmp, RetSQLName("SE2"))
					
					cEmpAnt := SM0->M0_CODIGO
					cFilAnt := SM0->M0_CODFIL

					If !Empty(cEmpAnt) .And. !Empty(cFilAnt)

						lIntMnk := cVarMK_INTMNK
						
						If lIntMnk
							ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | Selecionado para processamento - SM0: " + SM0->M0_CODIGO + "/" + SM0->M0_CODFIL))						
							AAdd(aEmpFil, {cEmpAnt, cFilAnt})
						EndIf

					EndIf

				EndIf

				SM0->(DBSkip())

			EndDo

			nEmps := Len(aEmpFil)
			For nE := 1 To nEmps
				If nE == nEmps
					lUltimo := .T.
				EndIf
				ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | StartJob U_WSMNK03 In�cio - Empresa: " + aEmpFil[nE,1] + " / Filial: " + aEmpFil[nE,2]))
				StartJob("U_WSMNK03", GetEnvServer(), .F., aEmpFil[nE,1], aEmpFil[nE,2], cMNKLote, lUltimo)
				ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | StartJob U_WSMNK03 Fim - Empresa: " + aEmpFil[nE,1] + " / Filial: " + aEmpFil[nE,2]))
			Next nE

		EndIf

		cResponse := '{ '
		cResponse += '"id": "' + cMNKLote + '"'
		cResponse += '} '

	EndIf

	ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList: " + cMessage))

	If !lReturn
		SetRestFault(nHTTPCode, EncodeUTF8(cMessage))
		::SetResponse(cResponse)
	Else
		::SetResponse(cResponse)
	EndIf

	MemoWrite(cLogDir + cLogArq + "_response.json", cResponse)

	ConOut(OEMToANSI(FWTimeStamp(2) + " * * * | payablesList Fim"))
	FWLogMsg("INFO", , "MONKEY", "payablesList", "999", "999", "Fim do Processo", 0, 0, {})

Return lReturn
//--< fim de arquivo >----------------------------------------------------------------------
