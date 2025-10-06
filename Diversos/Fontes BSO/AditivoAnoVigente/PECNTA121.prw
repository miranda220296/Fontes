#INCLUDE "Protheus.ch"
#INCLUDE "FWMVCDEF.CH"
/*
{Protheus.doc} CNTA121()
Ponto de entrada novo(Modelo MVC) na Medição do contranto
@Author		Ricardo Junior
@Since		12/09/2023
@Version	1.0
*/
User Function CNTA121()
	Local aParam := PARAMIXB
	Local xRet := .T.
	Local oModel := ''
	Local cIdPonto := ''
	Local cIdModel := ''
	Local nI		:=	0
	Local aArea		:=  FwGetArea()
	Local cFilOri	:=	xFilial('CND')
	Local cAlias01	:=	''
	Local cNumMed	:=	''

	If aParam <> NIL
		oModel  := aParam[1]
		cIdPonto:= aParam[2]
		cIdModel:= aParam[3]

        /*O evento de id <MODELVLDACTIVE> será sempre chamado ao iniciar uma operação com o modelo de dados via método Activate do MPFormModel,
        então para nos certificarmos que a validação só será executada no encerramento tal qual o p.e CN120ENVL, é necessário verificar se a chamada está sendo realizada
        através da função CN121MedEnc, pra isso utilizamos a função FwIsInCallStack
         */
		//If cIdPonto == 'CN121ATS'
		//	U_F1200401() // Rotina a ser executado por ultimo e ela não tem efeito de validação e sim de preparação
		//elseif cIdPonto == 'CN121PED'
		//	xRet := U_F1200718()//Ponto de entrada para tratamento de campos do pedido de compra
		if cIdPonto == 'FORMCOMMITTTSPOS' .And. cIdModel == "CNEDETAIL" .And. oModel:GetOperation() == 5
			//U_F1200715(Paramixb[01]) //Ajusta Flag da Medição de Contrato
			cFilOri		:=	xFilial('CND')
			cNumMed		:=	oModel:getValue("CNE_NUMMED")
			For nI := 01 To oModel:Length()
				oModel:GoLine(nI)

				If !oModel:IsDeleted()//aCols[nI][Len(aHeader) + 01] == .F.

					cAlias01 := GetNextAlias()

					BeginSql Alias cAlias01
                    SELECT	SC1.R_E_C_N_O_ NUMREC
                    FROM	%Table:SC1% SC1
                    WHERE 		SC1.%notDel%
                            AND SC1.C1_FILIAL	= %Exp:cFilOri%
                            AND SC1.C1_XNUMMED	= %Exp:cNumMed%
                            AND	SC1.C1_XITEMED	= %Exp:oModel:getValue("CNE_ITEM")%//%Exp:aCols[nI][nColItmMed]%
                            EndSql

					Do While !(cAlias01)->(Eof())
						SC1->(DbGoTo((cAlias01)->NUMREC))
						Reclock('SC1',.F.) 
						SC1->C1_FLAGGCT	:=	''
						SC1->C1_XNUMMED	:=	''
						SC1->C1_XITEMED	:=	''
						SC1->C1_XITMED	:=	'MEDICAO EXCLUIDA'
						SC1->C1_XOBSMED	:=	'MEDICAO EXCLUIDA'
						SC1->C1_PEDIDO  :=	''
						SC1->C1_ITEMPED :=	''
						SC1->(MsUnLock())
						(cAlias01)->(DbSkip())
					EndDo

					(cAlias01)->(DbCloseArea())
				EndIf
			Next nI

		EndIf
	EndIf
    FwRestArea(aArea)
Return xRet
