#Include 'Protheus.ch'
#INCLUDE 'RWMAKE.CH'
#INCLUDE "TopConn.ch"
#Include 'FWMVCDef.ch'
// #Include 'MATA094.ch'
// #Include "GCTXDEF.CH"
// #INCLUDE "MATA097.CH"
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE "FWEVENTVIEWCONSTS.CH"


#DEFINE OP_LIB	"001" // Liberado
#DEFINE OP_EST	"002" // Estornar
#DEFINE OP_SUP	"003" // Superior
#DEFINE OP_TRA	"004" // Transferir Superior
#DEFINE OP_REJ	"005" // Rejeitado
#DEFINE OP_BLQ	"006" // Bloqueio
#DEFINE OP_VIW	"007" // Visualizacao


/*/{Protheus.doc} FRPMED1
Fonte respons�vel pela melhoria do repasse m�dico
@type function
@author Lucas Miranda de Aguiar
@since 25/04/2023
@version 1.0
@return NIL
/*/ 


User Function fValR2()

	Local aArea := GetArea()
	Local lRet := .T.
	Local oModel   := FwModelActive()
	Local oModeCab := oModel:GetModel("MODEL_SC7p")
	Local cRepMed := oModeCab:GetValue("C7_XREPMED")

	If (cRepMed == "1" .Or. cRepMed == " ")
		Help("", 1, "F0100401", , "O campo de repasse m�dico est� definido como N�o.", 1, 0, , , , , , {"O nome da planilha s� pode ser digitado para SP de repasse m�dico."})
		M->C7_XPLANRE := ""
		lRet := .F.
	EndIf

	RestArea(aArea)
Return lRet


User Function fVldRmed()

	Local aArea := GetArea()
	Local cUser := __cUserId
	Local aGrpUser := UsrRetGrp(cUser)
	Local nX := 00
	Local lRet := .F.


	DbSelectArea("P41")
	P41->(DbGoTop())
	P41->(DbSetOrder(1))
	If P41->(DbSeek(xFilial("P41")+cUser+"1"))
		lRet := .T.
	Else
		P41->(DbGoTop())
		P41->(DbSetOrder(2))
		For nX := 01 To Len(aGrpUser)
			If P41->(DbSeek(xFilial("P41")+aGrpUser[nX]+"1"))
				lRet := .T.
				Exit
			EndIf
		Next nX
	EndIf

	RestArea(aArea)
Return lRet


/*/User Function xP41GRP(cCampo)

Local aArea := GetArea()
Local lEdita := .F.


Default cCampo := ""

If cCampo == "P41_GRUPO"
If ALTERA
If (Empty(P41->P41_USER) .And. Empty(M->P41_USER))
lEdita := .T.
Else
M->P41_USER := " "
EndIf
EndIf

If INCLUI
If Empty(M->P41_USER)
lEdita := .T.
Else
M->P41_USER := " "
EndIf
EndIf
EndIf

If cCampo == "P41_USER"
If ALTERA
If (Empty(P41->P41_GRUPO) .And. Empty(M->P41_GRUPO))
lEdita := .T.
Else
M->P41_USER := " "
EndIf
EndIf

If INCLUI
If Empty(M->P41_GRUPO)
lEdita := .T.
Else
M->P41_USER := " "
EndIf
EndIf
EndIf


RestArea(aArea)
Return lEdita/*/

User Function FCADP41()

	Local aRotAdic := {}
	Local bOK  := {||, fVeriDup()}
	Local aButtons := {}

	AxCadastro("P41", "Usu�rios Repasse m�dico", "U_fP41DEL()", "U_fP41OK()", aRotAdic, , bOK, , , , , aButtons, , )

Return(.T.)


User Function fP41DEL()
	Help(NIL, NIL, "Cadastro de produtos para classifica��o autom�tica", NIL, "A dele��o de registros est� desativada para esta rotina.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O produto deve ser inativado na fun��o ALTERAR."})
Return
User Function fP41OK()

	Local aArea := GetArea()
	Local lRet := .T.




	RestArea(aArea)
	Return lRet

Return



Static Function fVeriDup()
	Local aArea := GetArea()
	Local lRet := .T.
	Local cQuery := ""
	Local cAliasP41 := GetNextAlias()

	If ALTERA
		If (!Empty(M->P41_USER) .Or. !Empty(P41->P41_USER)) .And. (!Empty(M->P41_GRUPO) .Or. !Empty(P41->P41_GRUPO))
			Alert("N�o � poss�vel cadastrar usu�rio e grupo na mesma linha.")
			Return .F.
		EndIf
	EndIf

	If INCLUI
		If (!Empty(M->P41_USER) .And. !Empty(M->P41_GRUPO) )
			Alert("N�o � poss�vel cadastrar usu�rio e grupo na mesma linha.")
			Return .F.
		EndIf
	EndIf

	If ALTERA
		If !Empty(M->P41_USER) .Or. !Empty(P41->P41_USER)
			If M->P41_ATIVO == "1"
				cQuery := "SELECT * FROM " + RetSqlName("P41")
				cQuery += " WHERE D_E_L_E_T_ = ' ' AND P41_ATIVO = '1' AND P41_USER = '"
				If Empty(M->P41_USER)
					cQuery += P41->P41_USER
				Else
					cQuery += M->P41_USER
				EndIf
				cQuery += "' AND R_E_C_N_O_ <> '"+cValToChar(P41->(RECNO()))+"' "
				If Select( cAliasP41 ) > 0
					( cAliasP41 )->( DbCloseArea() )
				EndIf

				TcQuery cQuery Alias ( cAliasP41) New

				IF (cAliasP41)->(!EOF()) .And. M->P41_ATIVO == '1'
					lRet := .F.
					Help(NIL, NIL, "Cadastro de solicitantes de repasse m�dico", NIL, "J� existe um solicitante com o mesmo c�digo ativo na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do solicitante na tabela."})
					//Alert("J� existe um produto com o mesmo c�digo e status ATIVO na tabela. ")
				EndIf
			EndIf

			If !Empty(M->P41_GRUPO) .Or. !Empty(P41->P41_GRUPO)
				If M->P41_ATIVO == "1"
					cQuery := "SELECT * FROM " + RetSqlName("P41")
					cQuery += " WHERE D_E_L_E_T_ = ' ' AND P41_ATIVO = '1' AND P41_GRUPO = '"
					If Empty(M->P41_GRUPO)
						cQuery += P41->P41_GRUPO
					Else
						cQuery += M->P41_GRUPO
					EndIf
					cQuery += "' AND R_E_C_N_O_ <> '"+cValToChar(P41->(RECNO()))+"' "
					If Select( cAliasP41 ) > 0
						( cAliasP41 )->( DbCloseArea() )
					EndIf

					TcQuery cQuery Alias ( cAliasP41) New

					IF (cAliasP41)->(!EOF()) .And. M->P41_ATIVO == '1'
						lRet := .F.
						Help(NIL, NIL, "Cadastro de solicitantes de repasse m�dico", NIL, "J� existe um grupo com o mesmo c�digo ativo na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do grupo na tabela."})
						//Alert("J� existe um produto com o mesmo c�digo e status ATIVO na tabela. ")
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	If INCLUI
		If !Empty(M->P41_USER)
			cQuery := "SELECT * FROM " + RetSqlName("P41")
			cQuery += " WHERE D_E_L_E_T_ = ' ' AND P41_ATIVO = '1' AND P41_USER = '"
			cQuery += M->P41_USER + "'"

			If Select( cAliasP41 ) > 0
				( cAliasP41 )->( DbCloseArea() )
			EndIf

			TcQuery cQuery Alias ( cAliasP41 ) New

			IF (cAliasP41)->(!EOF()) .And. M->P41_ATIVO == '1'
				lRet := .F.
				Help(NIL, NIL, "Cadastro de solicitantes de repasse m�dico", NIL, "J� existe um solicitante com o mesmo c�digo ativo na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do solicitante na tabela."})
				//Alert("J� existe um produto com o mesmo c�digo e status ATIVO na tabela. ")
			EndIf
		EndIf

		If !Empty(M->P41_GRUPO)
			cQuery := "SELECT * FROM " + RetSqlName("P41")
			cQuery += " WHERE D_E_L_E_T_ = ' ' AND P41_ATIVO = '1' AND P41_GRUPO = '"
			cQuery += M->P41_GRUPO + "'"

			If Select( cAliasP41 ) > 0
				( cAliasP41 )->( DbCloseArea() )
			EndIf

			TcQuery cQuery Alias ( cAliasP41 ) New

			IF (cAliasP41)->(!EOF()) .And. M->P41_ATIVO == '1'
				lRet := .F.
				Help(NIL, NIL, "Cadastro de solicitantes de repasse m�dico", NIL, "J� existe um grupo com o mesmo c�digo ativo na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do solicitante na tabela."})
				//Alert("J� existe um produto com o mesmo c�digo e status ATIVO na tabela. ")
			EndIf
		EndIf
	EndIf


	If (lRet .And. INCLUI)
		M->P41_DTHRI := DtoS(Date())+" "+Time()
		M->P41_USRI  := __cUserId
		M->P41_NOMEI := UsrFullName(__CUSERID)
		M->P41_DTHRA := DtoS(Date())+" "+Time()
		M->P41_USRA  := __cUserId
		M->P41_NOMEA := UsrFullName(__CUSERID)
	ElseIf (lRet .And. ALTERA)
		M->P41_DTHRA := DtoS(Date())+" "+Time()
		M->P41_USRA  := __cUserId
		M->P41_NOMEA := UsrFullName(__CUSERID)
	EndIf
	RestArea(aArea)
	Return lRet


	//-------------------------------------------------------------------
	/*/{Protheus.doc} XMATA094()
	Aprova��o de repasse/honorario
	@author Lucas Miranda
	@since 20/04/2021
	@version 1.0
	Inicial
	@version 2.0
	Mudan�a na forma de busca dos dados selecionados, foi criada uma tabela tempor�ria para guardar os dados
	Fazendo com que a busca e exibi��o da tela fique muito mais r�pido.
	@return NIL
	/*/
//-------------------------------------------------------------------
User Function xApRepMed()

	Local aArea := GetArea()
	Private oBrowse     := Nil
	Private lMarcar      := .F.
	Private cFilBkp		:= cFilAnt
	Private aFiltro := {}
	Private lPendSub := .F.
	Private cDocBkp := ""
	Private cDocTipBkp := ""
	Private CARQTRB := ""
	Private nOpc	:= 0
	Private cStatsRV := ""
	Private cDocStatus := ""
	Private cDocTipo := ""
	Private nQtP := 0


	DbSelectArea("SAK")
	dbSetOrder(2)
	If !MsSeek(xFilial("SAK")+RetCodUsr())
		Help(" ",1,"A097APROV") //  Usuário não esta cadastrado como aprovador. O  acesso  e  a utilizacao desta rotina e destinada apenas aos usuários envolvidos no processo de aprovação de Pedido Compras definido pelos grupos de aprovação.
		dbSelectArea("SCR")
		dbSetOrder(1)
	Else
		If Pergunte("XAPRM",.T.)
			MsgRun("Criando tabela tempor�ria para inser��o dos dados...","Processando",{|| fCriaTRB() }) //Cria tabela tempor�ria para inser��o dos dados
			MsgRun("Coletando dados das aprova��es...","Processando",{|| fGetDados() })//Pega os dados da SCR a partir dos par�metros passados no Pergunte e Inclui na Tabela tempor�ria
			MsgRun("Criando browse para exibi��o dos dados...","Processando",{|| fBrowse() })//Cria um Markbrowse para o usu�rio executar o relat�rio
			fExclTRB()  //Exclui a tabela tempor�ria ap�s a opera��o
		EndIf
	EndIf
	RestArea(aArea)

	cFilAnt := cFilBkp
Return


/*/{Protheus.doc} fProcRP
Fun��o respons�vel por alimentar array com os documentos e realizar as opera��es
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 
User Function fProcRP(nOper)

	Local cMark := oMark:Mark()
	Local nX := 1
	Local aRecno := {}
	Local aRecnoTRB := {}
	Local cInfo := ""
	Local cTitulo := ""
	Local nReg := 0
	Local cCrObs := ""
	Local nCount := 0
	Local nLimite := GetNewPar("MV_XQTDMAS",20)
	Local lOk := .F.
	Local lContinua := .F.
	Local lAprov := .T.
	Local nMulta := 99999999
	Local nJuros := 99999999

	Local aTela := {}
	Local aTelaG := {}

	Private lPosTela := .F.
	Private aArrGrp := {}

	Default nOper := 001


	DbSelectArea("P35")
	DbSetOrder(1)
	DbGoTop()

	While P35->(!EOF())

		If P35->P35_TIPO == "1"
			nMulta := P35->P35_VALMIN
		ElseIf P35->P35_TIPO == "2"
			nJuros := P35->P35_VALMIN
		EndIf
		P35->(DbSkip())
	EndDo

	//Posiciona no primeiro registro da tabela tempor�ria.
	DbSelectArea((cArqTrb))
	(cArqTrb)->(DbGoTop())

	//Adiciona o RECNO da SCR, que est� gravado na tabela tempor�ria em um array, mas somente dos documentos que o usu�rio selecionou para a opera��o.
	If (nOper == 5 .Or. nOper == 6)
		While (cArqTRB)->(!EOF())
			If (!Empty((cArqTRB)->TR_PLANRP) .And. (cArqTRB)->CR_STATUS == "02")
				AADD(aTelaG, {(cArqTRB)->TR_PLANRP,(cArqTRB)->CR_TOTAL,(cArqTrb)->TR_RECNO})
			EndIf
			nCount := 1
			(cArqTRB)->(DbSkip())
		EndDo
	ElseIf nOper == 10
		While (cArqTRB)->(!EOF())
			If (!Empty((cArqTRB)->TR_PLANRP))
				AADD(aTelaG, {(cArqTRB)->TR_PLANRP,(cArqTRB)->CR_TOTAL,(cArqTrb)->TR_RECNO})
			EndIf
			nCount := 1
			(cArqTRB)->(DbSkip())
		EndDo
	Else
		While (cArqTrb)->(!EoF())
			If (cArqTrb)->TR_OK == cMark
				nCount++
				AADD(aRecno,(cArqTrb)->TR_RECNO)
				AADD(aRecnoTRB, (cArqTrb)->(RECNO()))
				AADD(aTela, {(cArqTRB)->CR_TIPO,(cArqTRB)->CR_TOTAL,(cArqTRB)->TR_RECNO})
			EndIf
			(cArqTrb)->(DbSkip())
		EndDo
	EndIf
	SetRegua(Len(aRecno))

	If nLimite < nCount
		Alert("N�o � poss�vel aprovar mais de " + cValToChar(nLimite)+ " documentos por vez!")
		//Realiza as opera��es nos registros que o usu�rio marcou.
	ElseIf (nCount <= 0 .And. nOper <> 5)
		Alert("Ao menos um documento deve ser selecionado para aprova��o!")
	Else
		If nOper == 1
			fCriaTela(aTela)
			aRecno := AClone(aArrGrp)
		Elseif (nOper == 5 .Or. nOper == 6)
			fCrTGrupo(aTelaG, nOper)
			If lPosTela
				aRecno := AClone(aArrGrp)
			EndIf
		ElseIf nOper == 10//"relat�rio repasse"
			fCrTGrup2(aTelaG, nOper)
			lPosTela := .F.
		Else
			lPosTela := .T.
		EndIf
		If lPosTela
			For nX := 1 To Len(aRecno)
				DbSelectArea("SCR")
				DbGoto(aRecno[nX])
				nReg++
				IncRegua()
				lOk := .F.

				If SCR->CR_TIPO == "PC"
					DbSelectArea("SC7")
					DbSetOrder(1)
					If SC7->(DbSeek(SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)))
						If SC7->C7_XSOLPAG == "1"
							If (SC7->C7_XMULTA >= nMulta.Or. SC7->C7_XJURMUL >= nJuros)
								If !(SC7->C7_XMULTA == 0.00 .And. SC7->C7_XJURMUL == 0.00)
									lContinua := U_XAPRVMULJUR()
									If lContinua
										cMsgMulJur := "Esta solicita��o de pagamento possui valor de Multa ou Juros lan�ados. "  + Chr(13) + Chr(10)
										cMsgMulJur += "CODIGO DA FILIAL: " +  cValToChar(SC7->C7_FILIAL) + Chr(13) + Chr(10)
										cMsgMulJur += "NUMERO DA SP: " + cValToChar(SC7->C7_NUM) + Chr(13) + Chr(10)
										cMsgMulJur += "MULTA: R$ " + cValToChar(TRANSFORM(SC7->C7_XMULTA, "@E 99,999,999,999.99")) + Chr(13) + Chr(10)
										cMsgMulJur += "JUROS: R$ " + cValToChar(TRANSFORM(SC7->C7_XJURMUL, "@E 99,999,999,999.99"))  + Chr(13) + Chr(10)
										cMsgMulJur += "Deseja confirmar essa aprova��o?"
										//Pergunta se deseja aprovar SP com multa/Juros
										If !MsgYesNo(cMsgMulJur)
											lAprov := .F.
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf

				If lAprov

					//Mudo a filial antes da aprova��o.
					cFilAnt := SCR->CR_FILIAL

					If (nOper == 001 .Or. nOper == 005)
						cCrObs := "Aprovado via rotina de aprova��o de repasse/honor�rio."
						cInfo := "aprovados"
						cTitulo := "Aprova��o de repasse/honorario."
						nOpc := 4
						cStatsRV := "10"
						lOk := fProcessa("001",cCrObs)
					ElseIf nOper == 002
						cCrObs := "Bloqueado via rotina de aprova��o de repasse/honor�rio."
						cInfo := "bloqueados"
						cTitulo := "Bloqueio de repasse/honorario."
						nOpc := 6
						lOk := fProcessa("006",cCrObs)
					ElseIf nOper == 003
						cCrObs := "Estornado via rotina de aprova��o de repasse/honor�rio."
						cInfo := "estornados"
						cTitulo := "Estorno de repasse/honorario."
						nOpc := 5
						lOk := fProcessa("002",cCrObs)
					ElseIf (nOper == 004 .Or. nOper == 006)
						cCrObs := "Rejeitado via rotina de aprova��o de repasse/honor�rio."
						cInfo := "rejeitados"
						cTitulo := "Rejei��o de repasse/honorario."
						nOpc := 7
						cStatsRV := "11"
						lOk := fProcessa("005",cCrObs)
					EndIf
				EndIf

			Next nX

			fNoShow()//Limpa todos os dados da tabela
			fRefresh()//Repopula a tabela com os dados das aprova��es ainda com o status que o usu�rio passou.
			If !Empty(cTitulo)
				MsgInfo("Fim do processamento",cTitulo)
			Else
				MsgInfo("Fim do processamento","Libera��o Repasse/Honor�rios")
			EndIf
		EndIf
	EndIf
	oBrowse:Refresh()

Return

/*/{Protheus.doc} fProcessa
Fun��o respons�vel por processar a opera��o de Libera��o/Bloqueio/Rejei��o/Estorno
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 
Static Function fProcessa(cIdOperac,cObsCr)

	Local aArea         := {}
	Local oModel        := Nil
	Local lRetorno		:= .T.
	Local cUpdate		:= ""
	Local lLiberaRV		:= .F.
	Local aGrp			:= {}
	Local cGrps			:= ""
	Local nX 			:= 01
	Local lRv			:= .F.
	Local cRvNum		:= ""
	Local lFirstUsr		:= .F.
	Private aCamposC7   := {}
	Private aCamposDBL  := {}
	Private cFieldSC7   := ""

	Default cIdOperac := ""
	Default cObsCr := ""


	aArea := {GetArea(), SCR->(GetArea())}
	If cIdOperac == "002" //Caso seja estorno chamo a rotina padr�o direto.
		If A094VldEst()
			RecLock("SCR",.F.)
			SCR->CR_OBS := cObsCr
			MsUnlock()
		EndIf
	Else//Outras opera��es eu realizo a opera��o via MVC
		//Tratamento diferente caso seja RV, para evitar error.log caso o usu�rio n�o tenha amarra��o com o contrato
		If (SCR->CR_TIPO == "RV" .And. cIdOperac == "001")
			lRv := .T.
			dbSelectArea("CNN")
			dbSetOrder(1)
			If !DbSeek(xFilial("CNN")+RetCodUsr()+Padr(SCR->CR_NUM,TamSx3("CNN_CONTRA")[1]))
				lFirstUsr := .T.
				cRvNum := SCR->CR_NUM
				//����������������������������������������������Ŀ
				//� Carrega Grupos do usuario                    �
				//������������������������������������������������
				aGrp := FWSFUsrGrps(RetCodUsr())

				For nX := 01 to Len(aGrp)
					cGrps += "'"+aGrp[nX]+"',"
				Next

				cGrps := SubStr(cGrps,1,Len(cGrps)-1)

				RecLock("CNN",.T.)
				CNN->CNN_FILIAL := xFilial("CNN")
				CNN->CNN_CONTRA := AllTrim(SCR->CR_NUM)
				CNN->CNN_USRCOD := RetCodUsr()
				CNN->CNN_GRPCOD	:= Iif(Len(aGrp) > 0,aGrp[1],"")
				CNN->CNN_TRACOD := "001"
				CNN->(MsUnlock())
			EndIf
			lLastNvl := fLastNvl(SCR->(RECNO()))
			lLiberaRV := MaAlcDoc({SCR->CR_NUM,SCR->CR_TIPO,SCR->CR_TOTAL,SCR->CR_APROV,,SCR->CR_GRUPO,,,,,cObsCr},SCR->CR_DATALIB,nOpc,,,SCR->CR_ITGRP)
			If (lLiberaRV .And. lLastNvl)
				If (nOpc == 4 .Or. nOpc == 7)

					cUpdate := "UPDATE "+ RetSqlName("CN9")+ " SET CN9_SITUAC = '10' WHERE D_E_L_E_T_ = ' '"
					cUpdate += " AND CN9_FILIAL = '"+xFilial("CN9")+"'"
					cUpdate += " AND CN9_NUMERO = '"+Padr(AllTrim(SCR->CR_NUM),TamSx3("CN9_NUMERO")[1])+"'"
					cUpdate += " AND CN9_SITUAC = '05' "

					If TcSQLExec( cUpdate ) != 0
						Conout("Erro ao tentar atualizar a tabela CN9" + CRLF + TcSQLError())
					Else
						CN9->(dbCommit())
					EndIf

					If CN9->(MsSeek(xFilial("CN9")+AllTrim(SCR->CR_NUM)))
						RecLock("CN9",.F.)
						CN9->CN9_SITUAC := "05"
						CN9->(MsUnLock())
					EndIf
				EndIf
			EndIf
		Else

			A094SetOp(cIdOperac)

			//Trecho copiado do padr�o para evitar errorlog
			aCamposC7   := MtGetFec("SC7", "C7")
			aCamposDBL  := MtGetFec("DBL", "DBL")

			AEval(aCamposC7, {|campo| cFieldSC7 += "|" + campo})

			oModel := FwLoadModel("MATA094")

			oModel:SetOperation(4)//Opera��o de UPDATE

			//Tira Poss�veis locks de tudo
			XA097Lock(AllTrim(SCR->CR_NUM),AllTrim(SCR->CR_TIPO))


			If oModel:Activate()
				oModel:SetValue("FieldSCR", "CR_OBS", cObsCr)

				If oModel:VldData()
					Begin Transaction
						oModel:CommitData()
						lRetorno := .T.
						If (lRv .And. lFirstUsr)//Se o usu�rio n�o estava cadastrado na CNN eu deleto ele.
							DbselectArea("CNN")
							DbSetOrder(1)
							If DbSeek(xFilial("CNN")+RetCodUsr()+Padr(cRvNum,TamSx3("CNN_CONTRA")[1]))
								RecLock("CNN",.F.)
								CNN->(DbDelete())
								CNN->(MsUnLock())
							EndIf
						EndIf
					End Transaction
				Else
					lRetorno := .F.
				EndIf
			EndIf
			oModel:DeActivate()
		EndIf
	EndIf
	AEval(aArea, {|area| RestArea(area)})


Return lRetorno


//-------------------------------------------------------------------
/*/Function fCriaTRB()
Cria��o da tabela tempor�ria para insers�o dos dados da aprova��o.
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
Inicial
@return NIL
/*/
//-------------------------------------------------------------------
Static Function fCriaTRB()

	Local aArea := GetArea()
	Local cAlias := "SCR"
	Local aFields := {}
	Local nX := 1
	Local cType := ""
	Local aCampos 	:= {}
	Local aFields 	:= {}
	Local oTempTable:= Nil 
	Local cAlias 	:= GetNextAlias()

	//-------------------
	//Cria��o do objeto
	//-------------------
	oTempTable := FWTemporaryTable():New( cAlias )

	aFields := FWSX3Util():GetAllFields( cAlias , .F. )

	//--------------------------
	//Monta os campos da tabela
	//--------------------------
	For nX := 01 To Len(aFields)
		cType := FWSX3Util():GetFieldType( aFields[nX] )
		If aFields[nX] == "CR_FILIAL"
			AAdd(aCampos,{aFields[nX],	cType,	8,	0})
			AAdd(aCampos,{"TR_DESCFIL","C",25,0})
			aADD(aFiltro,{"CR_FILIAL","Filial","C",8,0,"@!"})
		ElseIf aFields[nX] == "CR_TIPO"
			AAdd(aCampos,{aFields[nX],	cType,	2,	0})
			AAdd(aCampos,{"TR_PLANRP","C",25,0})
			aADD(aFiltro,{aFields[nX],AllTrim(GetSx3Cache(aFields[nX],"X3_TITULO")),cType,TamSX3(aFields[nX])[1],GetSx3Cache(aFields[nX],"X3_DECIMAL"),AllTrim(GetSx3Cache(aFields[nX],"X3_PICTURE"))})
			aADD(aFiltro,{"TR_PLANRP","Planilha Rep","C",25,0,""})
		Else
			AAdd(aCampos,{aFields[nX],	cType,	TamSX3(aFields[nX])[1],	GetSx3Cache(aFields[nX],"X3_DECIMAL")})
			aADD(aFiltro,{aFields[nX],AllTrim(GetSx3Cache(aFields[nX],"X3_TITULO")),cType,TamSX3(aFields[nX])[1],GetSx3Cache(aFields[nX],"X3_DECIMAL"),AllTrim(GetSx3Cache(aFields[nX],"X3_PICTURE"))})
		EndIf
	Next nX

	//Criar a tabela tempor�ria
	AAdd(aCampos,{"TR_OK"        	,"C",002						,0})
	AAdd(aCampos,{"TR_RECNO"       	,"N",015						,0})
	AADD(aCAmpos,{"TR_NOSHOW"		,"N",001						,0})

	oTemptable:SetFields( aFields )

	oTemptable:AddIndex("indice1", {"CR_FILIAL"} )
	oTemptable:AddIndex("indice2", {"CR_NUM"} )
	oTemptable:AddIndex("indice3", {"CR_TIPO"} )
	oTemptable:AddIndex("indice4", {"CR_FILIAL","CR_TIPO","CR_NUM"} )
	oTemptable:AddIndex("indice5", {"TR_PLANRP"} )

	//------------------
	//Cria��o da tabela
	//------------------
	oTempTable:Create()

	//A fun��o CriaTrab() retorna o nome de um arquivo de trabalho que ainda n�o existe e dependendo dos par�metros passados, pode criar um novo arquivo de trabalho.
	// cArqTrb   := CriaTrab(aCampos,.T.)

	// // //Criar indices
	// cIndice1 := Alltrim(CriaTrab(,.F.))
	// cIndice2 := cIndice1
	// cIndice3 := cIndice1
	// cIndice4 := cIndice1
	// cIndice5 := cIndice1

	// cIndice1 := Left(cIndice1,5) + Right(cIndice1,2) + "A"
	// cIndice2 := Left(cIndice2,5) + Right(cIndice2,2) + "B"
	// cIndice3 := Left(cIndice3,5) + Right(cIndice3,2) + "C"
	// cIndice4 := Left(cIndice4,5) + Right(cIndice4,2) + "D"
	// cIndice5 := Left(cIndice5,5) + Right(cIndice5,2) + "D"

	// //Se indice existir excluir
	// If File(cIndice1+OrdBagExt())
	// 	FErase(cIndice1+OrdBagExt())
	// EndIf
	// If File(cIndice2+OrdBagExt())
	// 	FErase(cIndice2+OrdBagExt())
	// EndIf
	// If File(cIndice3+OrdBagExt())
	// 	FErase(cIndice3+OrdBagExt())
	// EndIf
	// If File(cIndice4+OrdBagExt())
	// 	FErase(cIndice4+OrdBagExt())
	// EndIf
	// If File(cIndice5+OrdBagExt())
	// 	FErase(cIndice5+OrdBagExt())
	// EndIf

	// //A fun��o dbUseArea abre uma tabela de dados na �rea de trabalho atual ou na primeira �rea de trabalho dispon�vel
	// //dbUseArea(.T.,,cArqTrb,(cArqTrb),Nil,.F.)
	// dbUseArea(.T., __LocalDriver, cArqTrb, cArqTrb, .F.)

	// IndRegua(cArqTrb, cIndice1, "CR_FILIAL"	,,, "Indice Filial...")
	// IndRegua(cArqTrb, cIndice2, "CR_NUM",,, "Indice Nome...")
	// IndRegua(cArqTrb, cIndice3, "CR_TIPO",,, "Indice Tipo...")
	// IndRegua(cArqTrb, cIndice4, "CR_FILIAL+CR_TIPO+CR_NUM",,, "Filial+Tipo+Num...")
	// IndRegua(cArqTrb, cIndice5, "TR_PLANRP",,, "Planilha Rep...")

	// dbClearIndex()

	// //Acrescenta uma ou mais ordens de determinado �ndice de ordens ativas da �rea de trabalho.
	// dbSetIndex(cIndice1+OrdBagExt())
	// dbSetIndex(cIndice2+OrdBagExt())
	// dbSetIndex(cIndice3+OrdBagExt())
	// dbSetIndex(cIndice4+OrdBagExt())
	// dbSetIndex(cIndice5+OrdBagExt())

	RestArea(aArea)
Return



/*/{Protheus.doc} fGetDados
Fun��o respons�vel por alimentar a tabela tempor�ria com os dados da SCR
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 
Static Function fGetDados()

	Local aArea := GetArea()
	Local cAliasTmp := GetNextAlias()
	Local cQuery := ""
	Local aFields := {}
	Local nX := 1
	Local cAlias := "SCR"
	Local cStatusCr := ""
	Local cTipoCr := ""

	cDocStatus := MV_PAR01 //1 - Pendente | 2 - Aprovados | 3 - Todos | 4 - Bloqueado | 5 - Rejeitado
	cDocTipo := MV_PAR02 // 1 - Todos | 2 - Pc/SolPag | 3 - Solicita��o de compras | 4 - Contrato | 5 - Revis�o


	If !lPendSub
		cDocBkp := cDocStatus
		cDocTipBkp := cDocTipo
	Endif

	cDocStatus := cDocBkp
	cDocTipo := cDocTipBkp

	If cDocStatus == 1
		cStatusCr := "'02'"
	ElseIf cDocStatus == 2
		cStatusCr := "'03','05'"
	ElseIf cDocStatus == 3
		cStatusCr := ""
	ElseIf cDocStatus == 4
		cStatusCr := "'04'"
	ElseIf cDocStatus == 5
		cStatusCr := "'06'"
	EndIf

	If cDocTipo == 1
		cTipoCr := "TD"
	ElseIf cDocTipo == 2
		cTipoCr := "RP"
	ElseIf cDocTipo == 3
		cTipoCr := "HN"
	EndIf

	cQuery := fQrySCR(cStatusCr,cTipoCr)


	If Select( cAliasTmp ) > 0
		( cAliasTmp )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasTmp ) New
	While !( cAliasTmp )->( Eof() )

		aFields := FWSX3Util():GetAllFields( cAlias , .F. )

		DbSelectArea(cArqTrb)
		Reclock((cArqTrb),.T.)

		For nX := 01 To Len(aFields)
			If (aFields[nX] == "CR_TIPO" .And. (cAliasTmp)->&(aFields[nX]) == "PC")
				(cArqTrb)->&(aFields[nX]) := fGetTipo( cAliasTmp )
				(cArqTrb)->TR_PLANRP := fGetPlan(cAliasTmp)
			ElseIf aFields[nX] == "CR_FILIAL"
				(cArqTrb)->&(aFields[nX]) := (cAliasTmp)->&(aFields[nX])
				(cArqTrb)->TR_DESCFIL := AllTrim(FWFilName(cEmpAnt,(cAliasTmp)->&(aFields[nX])))
			Else
				If FWSX3Util():GetFieldType( aFields[nX] ) == "D"
					(cArqTrb)->&(aFields[nX]) := StoD((cAliasTmp)->&(aFields[nX]))
				ElseIf FWSX3Util():GetFieldType( aFields[nX] ) == "L"
					If (cAliasTmp)->&(aFields[nX]) == "T"
						(cArqTrb)->&(aFields[nX]) := .T.
					ElseIf (cAliasTmp)->&(aFields[nX]) == "F"
						(cArqTrb)->&(aFields[nX]) := .F.
					EndIf
				ElseIf FWSX3Util():GetFieldType( aFields[nX] ) <> "M"
					(cArqTrb)->&(aFields[nX]) := (cAliasTmp)->&(aFields[nX])
				EndIf
			EndIf

		Next nX
		//Adiciona o RECNO do registro da SCR na tabela tempor�ria para posicionar mais f�cil depois.
		(cArqTrb)->TR_RECNO := (cAliasTmp)->RECNO
		(cArqTrb)->(MsUnlock())
		( cAliasTmp )->( DbSkip() )
	EndDo
	( cAliasTmp )->( DbCloseArea() )


	RestArea(aArea)

Return


/*/{Protheus.doc} fBrowse 
Fun��o respons�vel por montar a tela com os dados filtrados da SCR
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 
Static Function fBrowse()

	Local cPicture := ""
	Local cTitulo := ""
	Local nAlign := 0
	Local nDecimal := 0
	Local cAlias  := "SCR"
	Local cCadastro := "Rotina de libera��o de Repasse/Honor�rios"
	Local bKeyF12    := { || MCFG6Invert(oBrowse:Mark(),lMarcar := !lMarcar ), oBrowse:Refresh(.T.)  }
	Local aSeek := {}
	Local cType := ""
   local nX
	DbSelectArea((cArqTrb))
	(cArqTrb)->(dbGoTop())

	aAdd(aSeek,{"Filial"	,{{"","C",TamSX3("CR_FILIAL")[1]	,0,"Filial"	,"@!"}} } )
	aAdd(aSeek,{"Numero"	,{{"","C",TamSX3("CR_NUM")[1]		,0,"Numero"	,"@!"}} } )
	aAdd(aSeek,{"Tipo"		,{{"","C",TamSX3("CR_TIPO")[1]		,0,"Tipo"	,"@!"}} } )
	aAdd(aSeek,{"Filial+Tipo+Num"	,{{"","C",TamSX3("CR_FILIAL")[1]+TamSX3("CR_TIPO")[1]+TamSX3("CR_NUM")[1]	,0,"Filial+Tipo+Num","@!"}} } )
	aAdd(aSeek,{"Planilha Rep"		,{{"","C",25		,0,"Planilha Rep"	," "}} } )

	oBrowse:= FWMarkBrowse():New()
	oBrowse:SetDescription(cCadastro) //Titulo da Janela
	oBrowse:SetParam(bKeyF12) // Seta tecla F12
	oBrowse:SetMenuDef("FRPMED1")
	oBrowse:SetAlias((cArqTrb)) //Indica o alias da tabela que ser� utilizada no Browse
	oBrowse:SetFieldMark("TR_OK") //Indica o campo que dever� ser atualizado com a marca no registro
	oBrowse:oBrowse:SetDBFFilter(.T.)
	oBrowse:oBrowse:SetFieldFilter(aFiltro)
	oBrowse:oBrowse:SetUseFilter(.T.) //Habilita a utiliza��o do filtro no Browse
	oBrowse:oBrowse:SetFixedBrowse(.T.)
	oBrowse:SetWalkThru(.F.) //Habilita a utiliza��o da funcionalidade Walk-Thru no Browse
	oBrowse:SetAmbiente(.T.) //Habilita a utiliza��o da funcionalidade Ambiente no Browse
	oBrowse:SetTemporary() //Indica que o Browse utiliza tabela tempor�ria
	oBrowse:oBrowse:SetSeek(.T.,aSeek) //Habilita a utiliza��o da pesquisa de registros no Browse
	oBrowse:oBrowse:SetFilterDefault("TR_NOSHOW != 1") //Indica o filtro padr�o do Browse

	//Adicionando legendas no Browse
	oBrowse:AddLegend("CR_STATUS=='01'", "BR_AZUL" , "Bloqueado (aguardando outros n�veis)" )
	oBrowse:AddLegend("CR_STATUS=='02'", "DISABLE" , "Aguardando Libera��o do usu�rio"  )
	oBrowse:AddLegend("CR_STATUS=='03'", "ENABLE"  , "Documento Liberado pelo usu�rio" )
	oBrowse:AddLegend("CR_STATUS=='04'", "BR_PRETO", "Documento Bloqueado pelo usu�rio" )
	oBrowse:AddLegend("CR_STATUS=='05'", "BR_CINZA", "Documento Liberado por outro usu�rio" )
	oBrowse:AddLegend("CR_STATUS=='06'", "BR_CANCEL","Documento Rejeitado pelo usu�rio" )

	aFields := FWSX3Util():GetAllFields( cAlias , .F. )
	For nX := 1 To Len(aFields)
		cPicture := GetSx3Cache( aFields[nX], "X3_PICTURE" )
		cTitulo := GetSx3Cache( aFields[nX], "X3_TITULO" )
		nDecimal :=	GetSx3Cache( aFields[nX], "X3_DECIMAL" )
		cType := FWSX3Util():GetFieldType( aFields[nX] )

		//aAdd(aSeek,{cTitulo	,{aFields[nX],cType,TamSX3(aFields[nX])[1]	,0,cTitulo	,cPicture }} )
		//aAdd(aSeek,{"Filial"	,{{"","C",TamSX3("C1_FILIAL")[1]	,0,"Filial"	,"@!"}} } )

		If aFields[nX] == "CR_FILIAL"
			nAlign := 8
		Else
			nAlign := GetSx3Cache( aFields[nX], "X3_TAMANHO" )
		EndIf

		oBrowse:SetColumns(MCFG006TIT(aFields[nX]     ,cTitulo    			 ,nX,cPicture,nAlign,nAlign,nDecimal))

		If aFields[nX] == "CR_FILIAL"
			nAlign := 25
			oBrowse:SetColumns(MCFG006TIT("TR_DESCFIL"    ,"Nome Filial" ,nX,cPicture,nAlign,nAlign,0))
		EndIf

		If aFields[nX] == "CR_TIPO"
			nAlign := 25
			oBrowse:SetColumns(MCFG006TIT("TR_PLANRP"    ,"Planilha do Repasse" ,nX,cPicture,nAlign,nAlign,0))
		EndIf
	Next nX

	oBrowse:bAllMark := { || MCFG6Invert(oBrowse:Mark(),lMarcar := !lMarcar ), oBrowse:Refresh(.T.)  }
	oBrowse:SetCustomMarkRec({ || fValidQtd() })


	//M�todo de ativa��o da classe
	oBrowse:Activate()

	oBrowse:oBrowse:Setfocus() //Seta o foco na grade

Return

Static Function fValidQtd()

	Local cAlias := (cArqTrb)
	Local aArea := (cAlias)->(GetArea())
	Local nLimite := GetNewPar("MV_XQTDMAS",10)
	Local nCount := 1
	Local nRec := (cAlias)->(RECNO())

	If !Empty(AllTrim((cAlias)->TR_OK))
		Reclock((cAlias),.F.)
		(cAlias)->TR_OK := ""
		(cAlias)->(MsUnLock())
	Else
		(cAlias)->(DbGoTop())
		While (!(cAlias)->( Eof() ))
			If !Empty(AllTrim((cAlias)->TR_OK))
				nCount++
			EndIf
			(cAlias)->( dbSkip() )
		EndDo
		If nCount > nLimite
			Alert("N�o � poss�vel selecionar mais de " + cValToChar(nLimite) + " registros!")
		Else
			(cAlias)->(DbGoTo(nRec))
			Reclock((cAlias),.F.)
			(cAlias)->TR_OK := oBrowse:Mark()
			(cAlias)->(MsUnLock())
		EndIf
	EndIf
	RestArea(aArea)
Return

/*/{Protheus.doc} MCFG006TIT
Fun��o respons�vel por criar as colunas do Browse
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 
Static Function MCFG006TIT(cCampo,cTitulo,nArrData,cPicture,nAlign,nSize,nDecimal)
	Local aColumn
	Local bData     := {||}
	Default nAlign     := 1
	Default nSize     := 20
	Default nDecimal:= 0
	Default nArrData:= 0

	If nArrData > 0
		bData := &("{||" + cCampo +"}") //&("{||oBrowse:DataArray[oBrowse:At(),"+STR(nArrData)+"]}")
	EndIf

	/* Array da coluna
	[n][01] T�tulo da coluna
	[n][02] Code-Block de carga dos dados
	[n][03] Tipo de dados
	[n][04] M�scara
	[n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
	[n][06] Tamanho
	[n][07] Decimal
	[n][08] Indica se permite a edi��o
	[n][09] Code-Block de valida��o da coluna ap�s a edi��o
	[n][10] Indica se exibe imagem
	[n][11] Code-Block de execu��o do duplo clique
	[n][12] Vari�vel a ser utilizada na edi��o (ReadVar)
	[n][13] Code-Block de execu��o do clique no header
	[n][14] Indica se a coluna est� deletada
	[n][15] Indica se a coluna ser� exibida nos detalhes do Browse
	[n][16] Op��es de carga dos dados (Ex: 1=Sim, 2=N�o)
	*/
	aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}
Return {aColumn}


/*/{Protheus.doc} MCFG6Invert
Fun��o que alimenta o bot�o F12 no browse
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return NIL
/*/ 

//Fun��o para marcar/desmarcar todos os registros do grid
Static Function MCFG6Invert(cMarca,lMarcar)
	Local cAlias := (cArqTrb)
	Local aArea := (cAlias)->(GetArea())
	Local nLimite := GetNewPar("MV_XQTDMAS",10)
	Local nCount := 0
	Local cMsg := ""

	Default cMarca := oBrowse:Mark()
	Default lMarcar := .T.


	If lMarcar

		dbSelectArea(cAlias)
		(cAlias)->( dbGoTop() )

		While !(cAlias)->( Eof() )
			If !Empty(AllTrim((cAlias)->TR_OK))
				nCount++
			EndIf
			(cAlias)->(DbSkip())
		EndDo

		If nCount >= nLimite
			MsgInfo("O limite de " + cValToChar(nLimite) + " marca��es  simult�neas foi atingido, nenhum registro ser� selecionado.","Libera��o Repasse/Honor�rios")
			Return .T.
		EndIf

		If nCount >= 1
			cMsg := "Voc� j� selecionou " + cValToChar(nCount) + iif(nCount == 1," registro "," registros ")
			cMsg += " do m�ximo de " + cValToChar(nLimite) + "."
			If nLimite-nCount > 1
				cMsg += CRLF + " Ser�o selecionados " + cValtoChar(nLimite-nCount) + " registros faltantes "
			Else
				cMsg += CRLF + " Ser� selecionado " + cValtoChar(nLimite-nCount) + " registro faltante "
			EndIf
			cMsg += " para completar o m�ximo de " +cValToChar(nLimite) + " registros permitidos para marca��o simult�nea."
			nLimite := nLimite-nCount
			MsgInfo(cMsg,"Libera��o Repasse/Honor�rios")
		EndIf
		nCount := 1
		(cAlias)->(DbGoTop())
		While (!(cAlias)->( Eof() ) .And. nCount <= nLimite)
			If Empty(AllTrim((cAlias)->TR_OK))
				RecLock( (cAlias), .F. )
				(cAlias)->TR_OK := cMarca
				MsUnlock()
				nCount++
			EndIf
			(cAlias)->( dbSkip() )
		EndDo
	Else
		While (!(cAlias)->( Eof() ) .And. nCount <= nLimite)
			RecLock( (cAlias), .F. )
			(cAlias)->TR_OK := '  '
			MsUnlock()
			nCount++
			(cAlias)->( dbSkip() )
		EndDo
	EndIf
	RestArea(aArea)
Return .T.


/*/{Protheus.doc} fExclTRB
Fun��o respons�vel por excluir a tabela tempor�ria
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
Static Function fExclTRB()

	(cArqTrb)->(DbCloseArea())

Return



/*/{Protheus.doc} fQrySCR
Fun��o respons�vel por fazer a query da SCR 
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return caracter
/*/ 
Static Function fQrySCR(cStatusCr,cTipoCR)

	Local aArea := GetArea()
	Local cQry := ""

	Default cStatusCr := ""
	Default cTipoCR := ""

	Cqry := " SELECT CR.*, R_E_C_N_O_ AS RECNO FROM " + RETSQLNAME("SCR") + " CR "
	Cqry += " WHERE D_E_L_E_T_ = ' ' "
	If !Empty(cStatusCr)
		Cqry += " AND CR_STATUS IN (" +cStatusCr+")"
	EndIf
	cQry += " AND CR_USER = '"+__CUSERID+"'"
	If cTipoCR == "TD"
		cQry += " AND CR_XRPMED IN ('R','H') "
	ElseIf cTipoCR == "RP"
		cQry += " AND CR_XRPMED = 'R' "
	ElseIf cTipoCR == "HN"
		cQry += " AND CR_XRPMED = 'H' "
	EndIF
	Cqry += " AND CR_TIPO = 'PC'"

	Cqry += " ORDER BY CR_FILIAL,CR_TIPO,CR_NUM"


	RestArea(aArea)
Return cQry

/*/{Protheus.doc} MenuDef
Defini��o de itens do menu do browse
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
Static Function MenuDef()

	Local aRotina := {} //Array utilizado para controlar opcao selecionada
	Local aOpcVIs	:= {}
	Local aOpcSup	:= {}
	Local aOpcBco	:= {}

	//ADD OPTION aOpcSup Title "Aprovar pelo superior"	    Action 'U_XAPRVSUP()'													 OPERATION 4 ACCESS 0
	//ADD OPTION aOpcSup Title "Transferir para superior"	    Action 'U_XTRANSSUP()'												     OPERATION 4 ACCESS 0

//	ADD OPTION aOpcBco Title "Incluir"	   				    Action 'U_XMT94fbRP(3)' 											 OPERATION 2 ACCESS 0
//	ADD OPTION aOpcBco Title "Excluir"	    				Action 'U_XMT94fbRP(5)' 											 OPERATION 2 ACCESS 0
//	ADD OPTION aOpcBco Title "Visualizar"	    			Action 'U_XMT94fbRP(1)' 											 OPERATION 2 ACCESS 0
//	ADD OPTION aOpcVis Title "Formul�rio da aprova��o"	    Action 'U_XXRPFORM()' 													 OPERATION 2 ACCESS 0
//	ADD OPTION aOpcVis Title "Documento emitido"	        Action 'U_XFDOCRPE()'											 OPERATION 2 ACCESS 0
//	ADD OPTION aOpcVis Title "Saldo para aprova��o"		    Action 'u_XfSldARPM()'												 OPERATION 2 ACCESS 0
//	ADD OPTION aRotina Title "Aprovar"              	    Action 'RptStatus({|| u_fProcRP(001)}, "Aguarde...", "Processando...")' OPERATION 4 ACCESS 0 	//"Aprovar"
//	ADD OPTION aRotina Title "Aprovar grupo"              	Action 'RptStatus({|| u_fProcRP(005)}, "Aguarde...", "Processando...")' OPERATION 4 ACCESS 0 	//"Aprovar"
//	ADD OPTION aRotina Title "Rejeitar"	                    Action 'RptStatus({|| u_fProcRP(004)}, "Aguarde...", "Processando...")'	 OPERATION 4 ACCESS 0  //"Rejeitar"
//	ADD OPTION aRotina Title "Rel. Aprova��es"	            Action 'RptStatus({|| u_fProcRP(010)}, "Aguarde...", "Processando...")'	 OPERATION 4 ACCESS 0  //"Rejeitar"
//	ADD OPTION aRotina Title "Visualizar"	                Action  aOpcVis														 OPERATION 2 ACCESS 0
//	ADD OPTION aRotina Title "Bloquear"	                    Action 'RptStatus({|| u_fProcRP(002)}, "Aguarde...", "Processando...")'	 OPERATION 4 ACCESS 0 	//"Bloquear"
//	ADD OPTION aRotina Title "Estornar"	                    Action 'RptStatus({|| u_fProcRP(003)}, "Aguarde...", "Processando...")'	 OPERATION 5 ACCESS 0 	//"Estornar"
//	ADD OPTION aRotina Title "Pendencias de subordinados"   Action 'U_PNDSBRP()'												 OPERATION 3 ACCESS 0
//	ADD OPTION aRotina Title "Superior"	                    Action  aOpcSup														 OPERATION 4 ACCESS 0
//	ADD OPTION aRotina Title "Banco espec�fico		"		Action 	aOpcBco	            										 OPERATION 4 ACCESS 0


	Aadd(aOpcBco , {"Incluir"    , 'U_XMT94fbRP(3)'        , 0, 2})
	Aadd(aOpcBco , {"Excluir"   , 'U_XMT94fbRP(5)'     , 0, 2})
	Aadd(aOpcBco , {"Visualizar"    ,'U_XMT94fbRP(1)'         , 0, 2})
	Aadd(aOpcVis , {"Formul�rio da aprova��o"    , 'VU_XXRPFORM()'        , 0, 2})
	Aadd(aOpcVis , {"Documento emitido"  ,  'U_XFDOCRPE()'     , 0, 2})
	Aadd(aOpcVis , {"Saldo para aprova��o"    ,'u_XfSldARPM()'         , 0, 2})
	Aadd(aRotina , {"Aprovar"    ,'RptStatus({|| u_fProcRP(001)}, "Aguarde...", "Processando...")'        , 0, 4})
	Aadd(aRotina , {"Aprovar grupo"    ,'RptStatus({|| u_fProcRP(005)}, "Aguarde...", "Processando...")'        , 0, 4})
	Aadd(aRotina , {"Rejeitar"    ,'RptStatus({|| u_fProcRP(004)}, "Aguarde...", "Processando...")'        , 0, 4})
	Aadd(aRotina , {"Rel. Aprova��es"    ,'RptStatus({|| u_fProcRP(010)}, "Aguarde...", "Processando...")'        , 0, 4})
	Aadd(aRotina , {"Rel. Aprova��es"    ,aOpcVis       , 0,2})
	Aadd(aRotina , {"Rel. Aprova��es"    ,'RptStatus({|| u_fProcRP(002)}, "Aguarde...", "Processando...")'       , 0,4})
	Aadd(aRotina , {"Rel. Aprova��es"    ,'RptStatus({|| u_fProcRP(003)}, "Aguarde...", "Processando...")'	       , 0,5})
	Aadd(aRotina , {"Pendencias de subordinados"   ,'U_PNDSBRP()'      , 0,3})
	Aadd(aRotina , {"Superior"   , aOpcSup	      , 0,4})
	Aadd(aRotina , {"Banco espec�fico		"   , aOpcBco	      , 0,4})






Return aRotina


/*/{Protheus.doc} fNoShow
Fun��o respons�vel por tirar os documentos j� lidos da tela ap�s o t�rmino das opera��es
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return
/*/ 
Static Function fNoShow()

	Local aArea := GetArea()
	DbSelectArea((cArqTrb))
	(cArqTrb)->(DbGoTop())
	While (cArqTrb)->(!EOF())
		If !Reclock((cArqTrb),.F.)
			(cArqTrb)->(MsUnlock())
			Reclock((cArqTrb),.F.)
			(cArqTrb)->( DbDelete() )
			(cArqTrb)->(MsUnlock())
			(cArqTrb)->(DbSkip())
		Else
			(cArqTrb)->( DbDelete() )
			(cArqTrb)->(MsUnlock())
			(cArqTrb)->(DbSkip())
		EndIf
	EndDo
	RestArea(aArea)
Return

/*/{Protheus.doc} XMT94fbco
Chamada do banco de conhecimento na rotina de aprova��o de repasse/honor�rio
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0 
@return 
/*/ 
User Function XMT94fbRP(nNum)

	Local aArea := GetArea()

	Default nNum := 1

	cFilAnt := (cArqTrb)->CR_FILIAL

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)

	If nNum == 1
		u_f0400101(1)
	ElseIf nNum == 3
		u_f0400101(3)
	ElseIf nNum == 5
		u_f0400101(5)
	EndIf
	RestArea(aArea)
Return


User Function XFDOCRPE()

	Local cRvNum := ""
	Local lFirstUsr := .F.
	Local aGrp := {}
	Local cGrps := ""
	Local nX

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	cFilAnt := (cArqTrb)->CR_FILIAL

	If (SCR->CR_TIPO == "RV" .Or. SCR->CR_TIPO == "CT")
		dbSelectArea("CNN")
		dbSetOrder(1)
		If !DbSeek(xFilial("CNN")+RetCodUsr()+Padr(SCR->CR_NUM,TamSx3("CNN_CONTRA")[1]))
			lFirstUsr := .T.
			cRvNum := SCR->CR_NUM
			//����������������������������������������������Ŀ
			//� Carrega Grupos do usuario                    �
			//������������������������������������������������
			aGrp := FWSFUsrGrps(RetCodUsr())

			For nX := 01 to Len(aGrp)
				cGrps += "'"+aGrp[nX]+"',"
			Next

			cGrps := SubStr(cGrps,1,Len(cGrps)-1)

			RecLock("CNN",.T.)
			CNN->CNN_FILIAL := xFilial("CNN")
			CNN->CNN_CONTRA := AllTrim(SCR->CR_NUM)
			CNN->CNN_USRCOD := RetCodUsr()
			CNN->CNN_GRPCOD	:= Iif(Len(aGrp) > 0,aGrp[1],"")
			CNN->CNN_TRACOD := "001"
			CNN->(MsUnlock())
		EndIf
	EndIf

	A097Visual(,,2)

	If lFirstUsr
		DbselectArea("CNN")
		DbSetOrder(1)
		If DbSeek(xFilial("CNN")+RetCodUsr()+Padr(cRvNum,TamSx3("CNN_CONTRA")[1]))
			RecLock("CNN",.F.)
			CNN->(DbDelete())
			CNN->(MsUnLock())
		EndIf
	EndIf
Return


/*/{Protheus.doc} XfSldApro
Fun��o para retornar o tipo "SP" caso seja solicita��o de pagamento
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
Static Function fGetTipo( cAliasTmp )

	Local aArea := GetArea()
	Local cAliasC7 := GetNextAlias()
	Local cQuery := ""
	Local cTipo := "PC"

	cQuery := " SELECT C7_XREPMED FROM "+ RETSQLNAME("SC7")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND C7_NUM = '"+( cAliasTmp )->CR_NUM+"'"
	cQuery += " AND C7_FILIAL = '"+( cAliasTmp )->CR_FILIAL+"'"
	cQuery += " AND C7_XSOLPAG = '1'"

	If Select( cAliasC7 ) > 0
		( cAliasC7 )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasC7 ) New
	If !( cAliasC7 )->( Eof() )
		If ( cAliasC7 )->C7_XREPMED == "2"
			cTipo := "RP"
		Elseif ( cAliasC7 )->C7_XREPMED == "3"
			cTipo := "HN"
		EndIf
	EndIf

	( cAliasC7 )->( DbCloseArea() )

	RestArea(aArea)
Return cTipo

Static Function fGetPlan( cAliasTmp )

	Local aArea := GetArea()
	Local cAliasC7 := GetNextAlias()
	Local cQuery := ""
	Local cPlan := ""

	cQuery := " SELECT C7_XPLANRE FROM "+ RETSQLNAME("SC7")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND C7_NUM = '"+( cAliasTmp )->CR_NUM+"'"
	cQuery += " AND C7_FILIAL = '"+( cAliasTmp )->CR_FILIAL+"'"
	cQuery += " AND C7_XSOLPAG = '1'"

	If Select( cAliasC7 ) > 0
		( cAliasC7 )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasC7 ) New
	If !( cAliasC7 )->( Eof() )
		cPlan := ( cAliasC7 )->C7_XPLANRE
	EndIf

	( cAliasC7 )->( DbCloseArea() )

	RestArea(aArea)
Return cPlan

/*/{Protheus.doc} XfSldApro
Logar na filial e ver o saldo da aprova��o
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
User Function XfSldARPM()

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	cFilAnt := (cArqTrb)->CR_FILIAL
	A097Consulta()
Return

/*/{Protheus.doc} XFORMAPRO
Logar na filial e ver o formul�rio do documento
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
User Function XXRPFORM()

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	cFilAnt := (cArqTrb)->CR_FILIAL
	A94Visual()

Return

/*/{Protheus.doc} XAPRVSUP
Logar na filial
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
User Function XAPRSRP()

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	cFilAnt := (cArqTrb)->CR_FILIAL
	A94ExSuper()
Return

/*/{Protheus.doc} XTRANSSUP
Logar na filial
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 
User Function XTRANSSRP()
	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	cFilAnt := (cArqTrb)->CR_FILIAL
	A94ExTrans()
Return


/*/{Protheus.doc} PENDUSB
Logar na filial
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 

User Function PNDSBRP()

	DbSelectArea("SCR")
	DbSetOrder(1)
	DbGoto((cArqTrb)->TR_RECNO)
	If Pergunte("XFILPENDSU",.T.)
		cFilAnt := MV_PAR01
		A097Ausente()
		lPendSub := .T.
		fNoShow()//Limpa todos os dados da tabela
		fRefresh()//Repopula a tabela com os dados das aprova��es ainda com o status que o usu�rio passou.
		oBrowse:Refresh()
	EndIf
	Return


	//--------------------------------------------------------------------
	/*/{Protheus.doc} XMT94coLan()
	Validacoes de bloqueio orcamentario. - C�pia do padr�o para compatibilidade
	@version 1.0
	@author Lucas Miranda de Aguiar
	@return NIL
	/*/
//--------------------------------------------------------------------
Static Function XMT94coLan()

	Local aArea    := GetArea()
	Local aAreaSC7 := SC7->(GetArea())
	Local ca094User:= RetCodUsr()
	Local cName    := ""
	Local lA097PCO := ExistBlock("A097PCO")
	Local lLanPCO  := .T.
	Local lRet     := .T.

	If lA097PCO
		cName   := UsrRetName(ca094User)
		lLanPCO := ExecBlock("A097PCO",.F.,.F.,{SC7->C7_NUM,cName,lLanPCO})
	EndIf

	If lLanPCO

		If SCR->CR_TIPO == "PC" .Or. SCR->CR_TIPO == "AE"
			dbSelectArea("SC7")
			DbSetOrder(1)
			DbSeek(xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM)))
		EndIf
		If lRet := PcoVldLan('000055','02','MATA097')
			If SCR->CR_TIPO == "NF"
				dbSelectArea("SF1")
			ElseIf SCR->CR_TIPO == "PC" .Or. SCR->CR_TIPO == "AE" .Or. SCR->CR_TIPO == "IP"
				While lRet .And. !Eof() .And. SC7->C7_FILIAL+Substr(SC7->C7_NUM,1,len(SC7->C7_NUM)) == xFilial("SC7")+Substr(SCR->CR_NUM,1,len(SC7->C7_NUM))
					lRet := PcoVldLan("000055","01","MATA097")
					dbSelectArea("SC7")
					dbSkip()
				EndDo
			ElseIf SCR->CR_TIPO == "CP"
				dbSelectArea("SC3")
			EndIf
		EndIf
		If !lRet
			PcoFreeBlq("000055")
		EndIf

	EndIf

	RestArea(aAreaSC7)
	RestArea(aArea)

Return lRet


/*/{Protheus.doc} Xa097Lock
Fun��o para tirar poss�veis locks
@type function
@author Lucas Miranda de Aguiar
@since 18/04/2021
@version 1.0
@return 
/*/ 

Static Function XA097Lock(cNumero,cTipo)

	Local aArea    	:= GetArea()
	Local lRet     	:= .F.
	Local nTamC7Num	:= TamSx3("C7_NUM")[1]

	If cTipo == "NF"
		aArea := SF1->(GetArea())
		dbSelectArea("SF1")
		dbSetOrder(1)
		If MsSeek(xFilial("SF1")+cNumero)
			If Reclock("SF1")
				lRet := .T.
				SF1->(MSUNLOCK())
			Else
				SF1->(MSUNLOCK())
			EndIf
		EndIf
	ElseIf cTipo == "PC" .Or. cTipo == "AE" .Or. cTipo == "IP"
		aArea := SC7->(GetArea())
		dbSelectArea("SC7")
		SC7->(dbSetOrder(1))
		If SC7->(MsSeek(xFilial("SC7") + cNumero))
			While SC7->(!Eof()) .And. SC7->C7_FILIAL + Padr(SC7->C7_NUM,nTamC7Num) == xFilial("SC7") + cNumero
				If RecLock("SC7")
					lRet := .T.
					SC7->(MSUNLOCK())
				Else
					SC7->(MSUNLOCK())
				Endif
				SC7->(dbSkip())
			EndDo
		EndIf
	ElseIf cTipo == "CP"
		aArea := SC3->(GetArea())
		dbSelectArea("SC3")
		dbSetOrder(1)
		If MsSeek(xFilial("SC3")+cNumero)
			While !Eof() .And. SC3->C3_FILIAL+Substr(SC3->C3_NUM,1,len(SC3->C3_NUM)) == xFilial("SC3")+cNumero
				If RecLock("SC3")
					SC3->(MSUNLOCK())
				Else
					SC3->(MSUNLOCK())
				Endif
				dbSkip()
			EndDo
		EndIf
	ElseIf cTipo == "MD"
		aArea := CND->(GetArea())
		dbSelectArea("CND")
		dbSetOrder(4)
		If MsSeek(xFilial("CND")+cNumero)
			If RecLock("CND")
				CND->(MSUNLOCK())
			Else
				CND->(MSUNLOCK())
			Endif
		EndIf
	ElseIf cTipo == "IM"
		aArea := CNE->(GetArea())
		dbSelectArea("CNE")
		dbSetOrder(4)
		If MsSeek(xFilial("CNE")+cNumero)
			If RecLock("CNE")
				CNE->(MSUNLOCK())
			Else
				CNE->(MSUNLOCK())
			Endif
		EndIf
	ElseIf cTipo $ "CT|RV"
		aArea := CN9->(GetArea())
		dbSelectArea("CN9")
		dbSetOrder(1)
		If MsSeek(xFilial("CN9")+cNumero)
			If RecLock("CN9")
				CN9->(MSUNLOCK())
			Else
				CN9->(MSUNLOCK())
			Endif
		EndIf
	ElseIf cTipo == "IC"
		aArea := CNB->(GetArea())
		cNumero := Left(allTrim(cNumero),TamSx3('CNB_CONTRA')[1])+Right(allTrim(cNumero),TamSx3('CNB_NUMERO')[1])
		dbSelectArea("CNB")
		CNB->(dbSetOrder(3)) //CNB_FILIAL+CNB_CONTRA+CNB_NUMERO+CNB_ITEM+CNB_REVISA
		If CNB->(MsSeek(xFilial("CNB")+cNumero))
			While !Eof() .And. AllTrim(CNB->(CNB_FILIAL+CNB_CONTRA+CNB_NUMERO)) == AllTrim(xFilial("CNB")+cNumero)
				If RecLock("CNB")
					CNB->(MSUNLOCK())
				Else
					CNB->(MSUNLOCK())
				Endif
				CNB->(dbSkip())
			EndDo
		EndIf
	ElseIf cTipo == "IR"
		aArea := CNB->(GetArea())
		dbSelectArea("CNB")
		dbSetOrder(1)
		If MsSeek(xFilial("CNB")+AllTrim(cNumero))
			While !Eof() .And. AllTrim(CNB->(CNB_FILIAL+CNB_CONTRA+CNB_REVISA)) == AllTrim(xFilial("CNB")+cNumero)
				If RecLock("CNB")
					CNB->(MSUNLOCK())
				Else
					CNB->(MSUNLOCK())
				Endif
				dbSkip()
			EndDo
		EndIf

	ElseIf cTipo == "GA" // Documento de Garantia (SIGAJURI)
		aArea := NV3->(GetArea())
		dbSelectArea("NV3")
		dbSetOrder(1)
		If MsSeek(xFilial("NV3")+Substr(AllTrim(SCR->CR_NUM),4,Len(AllTrim(SCR->CR_NUM))))
			If RecLock("NV3")
				NV3->(MSUNLOCK())
			Else
				NV3->(MSUNLOCK())
			Endif
		EndIf
	ElseIf cTipo == "SC" // Solicita��o de compra (SIGACOM)
		aArea := SC1->(GetArea())
		dbSelectArea("SC1")
		dbSetOrder(1)
		If MsSeek(xFilial("SC1")+AllTrim(cNumero))
			While !Eof() .And. SC1->C1_FILIAL+Substr(SC1->C1_NUM,1,len(SC1->C1_NUM)) == xFilial("SC1")+AllTrim(cNumero)
				If RecLock("SC1")
					SC1->(MSUNLOCK())
				Else
					SC1->(MSUNLOCK())
				EndIf
				dbSkip()
			End
		EndIf
	ElseIf	cTipo == "SA" // Solicita��o ao armaz�m (SIGAEST)
		aArea := SCP->(GetArea())
		dbSelectArea("SCP")
		dbSetOrder(1)
		If MsSeek(xFilial("SCP")+AllTrim(cNumero))
			While !Eof() .And. SCP->CP_FILIAL+Substr(SCP->CP_NUM,1,len(SCP->CP_NUM)) == xFilial("SCP")+AllTrim(cNumero)
				If RecLock("SCP")
					SCP->(MSUNLOCK())
				Else
					SCP->(MSUNLOCK())
				EndIf
				dbSkip()
			End
		EndIf
	ElseIf	cTipo == "ST" // Solicita��o de transfer�ncia (SIGAEST)
		aArea := NNS->(GetArea())
		dbSelectArea("NNS")
		dbSetOrder(1)
		If MsSeek(xFilial("NNS")+cNumero)
			If Reclock("NNS")
				NNS->(MSUNLOCK())
			Else
				NNS->(MSUNLOCK())
			EndIf
		EndIf
	EndIf

	RestArea(aArea)

Return


/*/{Protheus.doc} fLastNvl
Fun��o para verificar se � o ultimo n�vel da aprova��o de RV
@type function
@author Lucas Miranda de Aguiar
@since 04/06/2021
@version 1.0
@return 
/*/ 
Static Function fLastNvl(nRecno)

	Local aArea := GetArea()
	Local cNivel := ""
	Local lRet	:= .F.
	Local cAliasTmp := GetNextAlias()
	Local cQuery := ""

	Default nRecno := 0

	DbSelectArea("SCR")
	DbGoto(nRecno)
	cNivel := SCR->CR_NIVEL

	cQuery := " SELECT DISTINCT(CR_NIVEL) FROM "+ RETSQLNAME("SCR")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND CR_FILIAL = '"+SCR->CR_FILIAL+"'"
	cQuery += " AND CR_NUM = '"+SCR->CR_NUM+"'"
	cQuery += " AND CR_TIPO = '"+SCR->CR_TIPO+"'"
	cQuery += " AND CR_GRUPO = '"+SCR->CR_GRUPO+"'"
	cQuery += " ORDER BY CR_NIVEL DESC"

	If Select( cAliasTmp ) > 0
		( cAliasTmp )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasTmp ) New

	If !( cAliasTmp )->( Eof() )
		If cNivel == ( cAliasTmp )->CR_NIVEL
			lRet := .T.
		EndIf
	EndIf

	RestArea(aArea)
Return lRet



/*/{Protheus.doc} fRefresh
Fun��o respons�vel por atualizar a tabela tempor�ria
@type function
@author Lucas Miranda de Aguiar
@since 21/06/2021
@version 1.0
@return NIL
/*/ 
Static Function fRefresh()

	Local aArea := GetArea()
	Local cAliasTmp := GetNextAlias()
	Local cQuery := ""
	Local aFields := {}
	Local nX := 1
	Local cAlias := "SCR"
	Local cStatusCr := ""
	Local cTipoCr := ""


	If cDocStatus == 1
		cStatusCr := "'02'"
	ElseIf cDocStatus == 2
		cStatusCr := "'03','05'"
	ElseIf cDocStatus == 3
		cStatusCr := ""
	ElseIf cDocStatus == 4
		cStatusCr := "'04'"
	ElseIf cDocStatus == 5
		cStatusCr := "'06'"
	EndIf

	If cDocTipo == 1
		cTipoCr := "TD"
	ElseIf cDocTipo == 2
		cTipoCr := "RP"
	ElseIf cDocTipo == 3
		cTipoCr := "HN"
	EndIf

	cQuery := fQrySCR(cStatusCr,cTipoCr)


	If Select( cAliasTmp ) > 0
		( cAliasTmp )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasTmp ) New
	While !( cAliasTmp )->( Eof() )

		aFields := FWSX3Util():GetAllFields( cAlias , .F. )

		DbSelectArea(cArqTrb)
		Reclock((cArqTrb),.T.)

		For nX := 01 To Len(aFields)
			If (aFields[nX] == "CR_TIPO" .And. (cAliasTmp)->&(aFields[nX]) == "PC")
				(cArqTrb)->&(aFields[nX]) := fGetTipo( cAliasTmp )
				(cArqTrb)->TR_PLANRP := fGetPlan(cAliasTmp)
			ElseIf aFields[nX] == "CR_FILIAL"
				(cArqTrb)->&(aFields[nX]) := (cAliasTmp)->&(aFields[nX])
				(cArqTrb)->TR_DESCFIL := AllTrim(FWFilName(cEmpAnt,(cAliasTmp)->&(aFields[nX])))
			Else
				If FWSX3Util():GetFieldType( aFields[nX] ) == "D"
					(cArqTrb)->&(aFields[nX]) := StoD((cAliasTmp)->&(aFields[nX]))
				ElseIf FWSX3Util():GetFieldType( aFields[nX] ) == "L"
					If (cAliasTmp)->&(aFields[nX]) == "T"
						(cArqTrb)->&(aFields[nX]) := .T.
					ElseIf (cAliasTmp)->&(aFields[nX]) == "F"
						(cArqTrb)->&(aFields[nX]) := .F.
					EndIf
				ElseIf FWSX3Util():GetFieldType( aFields[nX] ) <> "M"
					(cArqTrb)->&(aFields[nX]) := (cAliasTmp)->&(aFields[nX])
				EndIf
			EndIf

		Next nX
		//Adiciona o RECNO do registro da SCR na tabela tempor�ria para posicionar mais f�cil depois.
		(cArqTrb)->TR_RECNO := (cAliasTmp)->RECNO
		(cArqTrb)->(MsUnlock())
		( cAliasTmp )->( DbSkip() )
	EndDo
	( cAliasTmp )->( DbCloseArea() )


	RestArea(aArea)

Return

Static Function fCrTGrupo(aTelaG,nOper)

	Local nLargBtn      := 50
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabe�alho
	Private oSayModulo, cSayModulo := "Rede D'Or"
	Private oSayTitulo, cSayTitulo := 'Aprova��o por Planilha'
	Private oSaySubTit, cSaySubTit := 'Resumo da aprova��o'
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := 1050//aSize[5]
	Private nJanAltu := 420//aSize[6]
	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontMod    := TFont():New(cFontUti, , -38)
	Private oFontSub    := TFont():New(cFontUti, , -20)
	Private oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	Private oFontBtn    := TFont():New(cFontUti, , -14)
	Private oFontSay    := TFont():New(cFontUti, , -12)
	//Grid
	Private aCampos := {}
	Private cAliasTmp := GetNextAlias()
	Private aColunas := {}

	Default nOper := 5
	//Campos da Tempor�ria
	aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marca��o
	aAdd(aCampos, { "PLAN" , "C", 30, 0 })
	//aAdd(aCampos, { "DESCTP", "C", 25,  0 })
	aAdd(aCampos, { "QTD", "N", 5,  0 })
	aAdd(aCampos, { "TOT_PEND", "C", 15,  0 })
	aAdd(aCampos, { "TOT_APROV", "C", 15,  0 })
	aAdd(aCampos, { "TOT_REJEIT", "C", 15,  0 })
	aAdd(aCampos, { "TOT_PLAN", "C", 15,  0 })

	//Cria a tabela tempor�ria
	oTempTable:= FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaColsg()

	//Popula a tabela tempor�ria
	Processa({|| fPopulag(aTelaG)}, "Processando...")

	//Cria a janela
	If nOper == 5
		DEFINE MSDIALOG oDlgPulo TITLE "Aprova��o por Planilha"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL
	Else
		cSayTitulo := 'Rejei��o por Planilha'
		cSaySubTit := 'Resumo da rejei��o'
		DEFINE MSDIALOG oDlgPulo TITLE "Rejei��o por Planilha"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL
	EndIf

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de t�tulo, a superior e a do calend�rio
	oFWLayer:addLine("TIT", 15, .F.)
	oFWLayer:addLine("COR", 90, .F.)

	//Adicionando as colunas das linhas
	oFWLayer:addCollumn("HEADERTEXT",   060, .T., "TIT")
	oFWLayer:addCollumn("BTNOK",     	100, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR",      100, .T., "TIT")
	oFWLayer:addCollumn("COLGRID",      100, .T., "COR")

	//Criando os paineis
	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNOK",      "TIT")
	oPanGrid   := oFWLayer:GetColPanel("COLGRID",    "COR")

	//T�tulos e SubT�tulos
	oSayModulo := TSay():New(004, 008, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 100, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 100, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os bot�es
	oBtnSair := TButton():New(006, 9, "Confirmar",             oPanSair, {|| fRetArray(aTelaG,cAliasTmp),oDlgPulo:End(),lPosTela := .T.}, 70, 018, , oFontBtn, , .T., , , , , , )
	oBtnSair := TButton():New(006, 80, "Cancelar",             oPanSair, {|| oDlgPulo:End()}, 70, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWMarkBrowse():New()
	oGetGrid:SetDataTable()
	//oGetGrid:SetInsert(.F.)
	//oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp)
	oGetGrid:DisableReport()
	oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFieldMark('OK')
	oGetGrid:SetFontBrowse(oFontSay)
	oGetGrid:SetColumns(aColunas)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:SetCustomMarkRec({ || fOk(oGetGrid) })
	oGetGrid:Activate()
	Activate MsDialog oDlgPulo Centered
	oTempTable:Delete()
Return

Static Function fOk()

	Local aArea := (cAliasTmp)->(GetArea())
	Local cMark := oGetGrid:Mark()

	If !Empty((cAliasTmp)->OK)
		Reclock((cAliasTmp),.F.)
		(cAliasTmp)->OK := ""
		(cAliasTmp)->(MsUnLock())
	Else
		Reclock((cAliasTmp),.F.)
		(cAliasTmp)->OK := cMark
		(cAliasTmp)->(MsUnLock())
	EndIf
Return

Static Function fRetArray2(aTelaG,cAliasTmp)

	Local cPlanilhas := ""
	Local nZ := 0
	Local nY := 0
	Local aPlanilhas := {}

	(cAliasTmp)->(DbGoTop())

	aArrGrp := {}

	While (cAliasTmp)->(!EOF())
		If !Empty((cAliasTmp)->OK)
			cPlanilhas += (cAliasTmp)->TIPO
		EndIf
		(cAliasTmp)->(DbSkip())
	EndDo

	aPlanilhas := StrTokArr(cPlanilhas,"|")

	For nY := 01 To Len(aPlanilhas)

		For nZ := 01 To Len(aTelaG)
			If AllTrim(aPlanilhas[nY]) == AllTrim(aTelaG[nZ][1])
				AADD(aArrGrp,aTelaG[nZ][3])
			EndIf
		Next nZ

	Next nY

Return

Static Function fRetArray(aTelaG,cAliasTmp)

	Local cPlanilhas := ""
	Local nZ := 0
	Local nY := 0
	Local aPlanilhas := {}

	(cAliasTmp)->(DbGoTop())

	aArrGrp := {}

	While (cAliasTmp)->(!EOF())
		If !Empty((cAliasTmp)->OK)
			cPlanilhas += (cAliasTmp)->PLAN+"|"
		EndIf
		(cAliasTmp)->(DbSkip())
	EndDo

	aPlanilhas := StrTokArr(cPlanilhas,"|")

	For nY := 01 To Len(aPlanilhas)

		For nZ := 01 To Len(aTelaG)
			If AllTrim(aPlanilhas[nY]) == AllTrim(aTelaG[nZ][1])
				AADD(aArrGrp,aTelaG[nZ][3])
			EndIf
		Next nZ

	Next nY

Return

Static Function fRetArray3(aTelaG,cAliasTmp)

	Local cPlanilhas := ""
	Local nZ := 0
	Local nY := 0
	Local aPlanilhas := {}

	(cAliasTmp)->(DbGoTop())

	aArrGrp := {}

	For nZ := 01 To Len(aTelaG)
		AADD(aArrGrp,aTelaG[nZ][3])
	Next nZ

Return

Static Function fCriaColsg2()
	Local nAtual   := 0
	Local aColunas := {}
	Local aEstrut  := {}
	Local oColumn

	//Adicionando campos que ser�o mostrados na tela
	//[1] - Campo da Temporaria
	//[2] - Titulo
	//[3] - Tipo
	//[4] - Tamanho
	//[5] - Decimais
	//[6] - M�scara
	aAdd(aEstrut, {"PLAN", "Planilha",             "C", 25,    0, ""})
	aAdd(aEstrut, {"QTD", "Quantidade selecionada",             "N", 5,    0, ""})
	aAdd(aEstrut, {"TOT_PEND", "Total pendente",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_APROV", "Total aprovado",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_REJEIT", "Total rejeitado",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_PLAN", "Total da planilha",             "C", 15,  0  , ""})



	//Percorrendo todos os campos da estrutura
	For nAtual := 1 To Len(aEstrut)
		//Cria a coluna
		oColumn := FWBrwColumn():New()
		oColumn:SetData(&("{|| (cAliasTmp)->" + aEstrut[nAtual][1] +"}"))
		oColumn:SetTitle(aEstrut[nAtual][2])
		oColumn:SetType(aEstrut[nAtual][3])
		oColumn:SetSize(aEstrut[nAtual][4])
		oColumn:SetDecimal(aEstrut[nAtual][5])
		oColumn:SetPicture(aEstrut[nAtual][6])
		//oColumn:bHeaderClick := &("{|| fOrdena('" + aEstrut[nAtual][1] + "') }")

		//Adiciona a coluna
		aAdd(aColunas, oColumn)
	Next
Return aColunas

Static Function fCriaCols2()
	Local nAtual   := 0
	Local aColunas := {}
	Local aEstrut  := {}
	Local oColumn

	//Adicionando campos que ser�o mostrados na tela
	//[1] - Campo da Temporaria
	//[2] - Titulo
	//[3] - Tipo
	//[4] - Tamanho
	//[5] - Decimais
	//[6] - M�scara
	aAdd(aEstrut, {"PLAN", "Planilha",             "C", 25,    0, ""})
	aAdd(aEstrut, {"QTD", "Qtd de documentos",             "N", 5,    0, ""})
	aAdd(aEstrut, {"TOT_PEND", "Total pendente",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_APROV", "Total aprovado",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_REJEIT", "Total rejeitado",             "C", 15,  0  , ""})
	aAdd(aEstrut, {"TOT_PLAN", "Total da planilha",             "C", 15,  0  , ""})



	//Percorrendo todos os campos da estrutura
	For nAtual := 1 To Len(aEstrut)
		//Cria a coluna
		oColumn := FWBrwColumn():New()
		oColumn:SetData(&("{|| (cAliasTmp)->" + aEstrut[nAtual][1] +"}"))
		oColumn:SetTitle(aEstrut[nAtual][2])
		oColumn:SetType(aEstrut[nAtual][3])
		oColumn:SetSize(aEstrut[nAtual][4])
		oColumn:SetDecimal(aEstrut[nAtual][5])
		oColumn:SetPicture(aEstrut[nAtual][6])
		//oColumn:bHeaderClick := &("{|| fOrdena('" + aEstrut[nAtual][1] + "') }")

		//Adiciona a coluna
		aAdd(aColunas, oColumn)
	Next
Return aColunas


Static Function fPopulag(aTelag)

	Local nQtPlan := 0
	Local nTotPlan := 0
	Local cPlanilhas := ""
	Local aPlanilhas := {}
	Local nX := 0
	Local nY := 0
	Local nZ := 0
	Local aResult := {}
	Local aTot := {}

	For nX := 1 To Len(aTelag)

		If !(AllTrim(aTelaG[nX][01]) $ AllTrim(cPlanilhas))
			If nX <> Len(aTelaG)
				cPlanilhas += aTelaG[nX][01]+"|"
			Else
				cPlanilhas += aTelaG[nX][01]
			EndIf
		EndIf
	Next nX

	aPlanilhas := StrTokArr(cPlanilhas,"|")

	For nY := 01 To Len(aPlanilhas)

		For nZ := 01 To Len(aTelaG)
			If AllTrim(aPlanilhas[nY]) == AllTrim(aTelaG[nZ][1])
				nQtPlan++
				nTotPlan := nTotPlan + aTelaG[nZ][2]
			EndIf
		Next nZ

		aTot := fGetTot(aPlanilhas[nY])
		RecLock(cAliasTmp, .T.)
		(cAliasTmp)->OK := Space(2)
		(cAliasTmp)->PLAN := aPlanilhas[nY]
		(cAliasTmp)->TOT_PEND := AllTrim(Transform(NOROUND(nTotPlan,5), "@E 999,999.99" ))
		(cAliasTmp)->TOT_APROV := AllTrim(Transform(NOROUND(aTot[1],5), "@E 999,999.99" ))
		(cAliasTmp)->QTD := nQtPlan
		(cAliasTmp)->TOT_REJEIT:= AllTrim(Transform(NOROUND(aTot[2],5), "@E 999,999.99" ))
		(cAliasTmp)->TOT_PLAN := AllTrim(Transform(NOROUND(aTot[3],5), "@E 999,999.99" ))
		(cAliasTmp)->(MsUnlock())

		nQtPlan := 0
		nTotPlan := 0
	Next nY


Return


Static Function fCriaTela(aTela)


	Local nLargBtn      := 50
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabe�alho
	Private oSayModulo, cSayModulo := "Rede D'Or"
	Private oSayTitulo, cSayTitulo := 'Aprova��o de repasse m�dico'
	Private oSaySubTit, cSaySubTit := 'Resumo da aprova��o'
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := 800//aSize[5]
	Private nJanAltu := 420//aSize[6]
	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontMod    := TFont():New(cFontUti, , -38)
	Private oFontSub    := TFont():New(cFontUti, , -20)
	Private oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	Private oFontBtn    := TFont():New(cFontUti, , -14)
	Private oFontSay    := TFont():New(cFontUti, , -12)
	//Grid
	Private aCampos := {}
	Private cAliasTmp := GetNextAlias()
	Private aColunas := {}

	//Campos da Tempor�ria
	aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marca��o
	aAdd(aCampos, { "PLAN" , "C", 30, 0 })
	aAdd(aCampos, { "TIPO" , "C", TamSX3("CR_TIPO")[1], 0 })
	aAdd(aCampos, { "DESCTP", "C", 25,  0 })
	aAdd(aCampos, { "QTD", "N", 5,  0 })
	aAdd(aCampos, { "Total", "C", 15,  0 })

	//Cria a tabela tempor�ria
	oTempTable:= FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaCols()

	//Popula a tabela tempor�ria
	Processa({|| fPopula(aTela)}, "Processando...")

	//Cria a janela
	DEFINE MSDIALOG oDlgPulo TITLE "Aprova��o de documentos"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de t�tulo, a superior e a do calend�rio
	oFWLayer:addLine("TIT", 15, .F.)
	oFWLayer:addLine("COR", 90, .F.)

	//Adicionando as colunas das linhas
	oFWLayer:addCollumn("HEADERTEXT",   060, .T., "TIT")
	oFWLayer:addCollumn("BTNOK",     	100, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR",      100, .T., "TIT")
	oFWLayer:addCollumn("COLGRID",      100, .T., "COR")

	//Criando os paineis
	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNOK",      "TIT")
	oPanGrid   := oFWLayer:GetColPanel("COLGRID",    "COR")

	//T�tulos e SubT�tulos
	oSayModulo := TSay():New(004, 008, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 100, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 100, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os bot�es
	oBtnSair := TButton():New(006, 9, "Confirmar",             oPanSair, {|| oDlgPulo:End(),lPosTela := .T.,fRetArray3(aTela,cAliasTmp)}, 70, 018, , oFontBtn, , .T., , , , , , )
	oBtnSair := TButton():New(006, 80, "Cancelar",             oPanSair, {|| oDlgPulo:End()}, 70, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWMarkBrowse():New()
	oGetGrid:SetDataTable()
	//oGetGrid:SetInsert(.F.)
	//oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp)
	oGetGrid:DisableReport()
	oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFieldMark('OK')
	oGetGrid:SetFontBrowse(oFontSay)
	oGetGrid:SetColumns(aColunas)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:SetCustomMarkRec({ || fOk(oGetGrid) })
	oGetGrid:Activate()
	Activate MsDialog oDlgPulo Centered
	oTempTable:Delete()
Return

Static Function fCriaCols()
	Local nAtual   := 0
	Local aColunas := {}
	Local aEstrut  := {}
	Local oColumn

	//Adicionando campos que ser�o mostrados na tela
	//[1] - Campo da Temporaria
	//[2] - Titulo
	//[3] - Tipo
	//[4] - Tamanho
	//[5] - Decimais
	//[6] - M�scara
	aAdd(aEstrut, {"TIPO", "Tipo dos Docs",                "C", TamSX3('CR_TIPO')[01],   0, ""})
	aAdd(aEstrut, {"DESCTP", "Descri��o do tipo",             "C", 25,    0, ""})
	aAdd(aEstrut, {"QTD", "Quantidade selecionada",             "N", 5,    0, ""})
	aAdd(aEstrut, {"Total", "Valor total dos documentos",             "C", 15,  0  , ""})

	//Percorrendo todos os campos da estrutura
	For nAtual := 1 To Len(aEstrut)
		//Cria a coluna
		oColumn := FWBrwColumn():New()
		oColumn:SetData(&("{|| (cAliasTmp)->" + aEstrut[nAtual][1] +"}"))
		oColumn:SetTitle(aEstrut[nAtual][2])
		oColumn:SetType(aEstrut[nAtual][3])
		oColumn:SetSize(aEstrut[nAtual][4])
		oColumn:SetDecimal(aEstrut[nAtual][5])
		oColumn:SetPicture(aEstrut[nAtual][6])
		//oColumn:bHeaderClick := &("{|| fOrdena('" + aEstrut[nAtual][1] + "') }")

		//Adiciona a coluna
		aAdd(aColunas, oColumn)
	Next
Return aColunas


Static Function fPopula(aTela)

	Local nTotalHN := 0
	Local nTotalRP := 0
	Local nQtHN    := 0
	Local nQtRP    := 0
	Local nX := 0

	For nX := 1 To Len(aTela)

		If aTela[nX][01] == "RP"
			nTotalRP := nTotalRP + aTela[nX][02]
			nQtRP++
		ElseIf aTela[nX][01] == "HN"
			nTotalHN := nTotalHN + aTela[nX][02]
			nQtHN++
		EndIf

	Next nX

	If nQtRP > 0
		RecLock(cAliasTmp, .T.)
		(cAliasTmp)->TIPO := "RP"
		(cAliasTmp)->QTD := nQtRP
		(cAliasTmp)->DESCTP := "Repasse M�dico"
		(cAliasTmp)->TOTAL := AllTrim(Transform(NOROUND(nTotalRP,5), "@E 999,999.99" ))
		(cAliasTmp)->(MsUnlock())
	EndIf
	If nQtHN > 0
		RecLock(cAliasTmp, .T.)
		(cAliasTmp)->TIPO := "HN"
		(cAliasTmp)->QTD := nQtHN
		(cAliasTmp)->DESCTP := "Honor�rios"
		(cAliasTmp)->TOTAL := AllTrim(Transform(NOROUND(nTotalHN,5), "@E 999,999.99" ))
		(cAliasTmp)->(MsUnlock())
	EndIf
Return


Static Function fGetTot(cPlan)

	//nOP 1 = Total Aprovado 
	//nOP 2 = Total Rejeitado
	//nOP 3 = Total Planilha

	Local aArea := SCR->(GetArea())
	Local nX := 01
	Local cIn := ""
	Local cQry := ""
	Local cAliasC7 := GetNextAlias()
	Local cJaLeu := ""
	Local cFilC7 := ""
	Local cNumC7 := ""
	Local aRet := {}
	Local nTotP := 0
	Local nAprov := 0
	Local nAprovD := 0
	Local nRej := 0

	Default nOp := 0
	Default cPlan := "99997875321"


	DBSELECTAREA("SCR")
	SCR->(DbSetOrder(1))


	cQry := "SELECT C7_FILIAL||C7_NUM CHAVE, COUNT(*) OVER () AS QT_LINHAS, SUM(C7_TOTAL) AS SOMA, SUM(SUM(C7_TOTAL)) OVER () AS TOTAL_PLAN FROM " + RetSqlName("SC7") + " WHERE D_E_L_E_T_ = ' ' AND C7_XSOLPAG = '1' AND C7_XPLANRE = '" +cPlan+"' GROUP BY C7_FILIAL||C7_NUM "

	If Select( cAliasC7 ) > 0
		( cAliasC7 )->( DbCloseArea() )
	EndIf

	TcQuery cQry Alias ( cAliasC7) New

	nQtp := 0
	While !( cAliasC7 )->( Eof() )

		If nTotp == 0
			nTotp := (cAliasC7)->TOTAL_PLAN
		EndIf

		If nQtp == 0
			nQtp := (cAliasC7)->QT_LINHAS
		EndIf


		cFilC7 := SUBSTR(( cAliasC7 )->CHAVE, 1, 8)
		cNumC7 := SUBSTR(( cAliasC7 )->CHAVE, 9, 6)

		SCR->(DbSeek(cfilC7+"PC"+cNumC7+Space(TamSX3("CR_NUM")[1]-6)))
		nAprovD := 0

		While !(SCR->(EOF())).And. SCR->CR_FILIAL == cFilC7 .And. SCR->CR_NUM == cNumC7+Space(TamSX3("CR_NUM")[1]-6) .And. SCR->CR_TIPO == "PC"
			If SCR->CR_STATUS == '03'
				If nAprovD == 0
					nAprovD := SCR->CR_TOTAL
				EndIF
			EndIf

			If SCR->CR_STATUS == '02'
				nAprovD := 0
				Exit
			EndIf

			If SCR->CR_STATUS == '06'
				nRej := nRej + SCR->CR_TOTAL
				Exit
			EndIf
			SCR->(DbSKip())
		EndDo

		nAprov := nAprov + nAprovD

		(cAliasC7)->(DbSkip())
	EndDo

	AADD(aRet,nAprov)
	AADD(aRet,nRej)
	AADD(aRet,nTotp)


	( cAliasC7 )->( DbCloseArea() )
	RestArea(aArea)
Return aRet


Static Function fCrTGrup2(aTelaG,nOper)

	Local nLargBtn      := 50
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabe�alho
	Private oSayModulo, cSayModulo := "Rede D'Or"
	Private oSayTitulo, cSayTitulo := 'Relat�rio de aprova��es'
	Private oSaySubTit, cSaySubTit := 'Repasse/Honor�rios'
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := 1050//aSize[5]
	Private nJanAltu := 420//aSize[6]
	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontMod    := TFont():New(cFontUti, , -38)
	Private oFontSub    := TFont():New(cFontUti, , -20)
	Private oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	Private oFontBtn    := TFont():New(cFontUti, , -14)
	Private oFontSay    := TFont():New(cFontUti, , -12)
	//Grid
	Private aCampos := {}
	Private cAliasTmp := GetNextAlias()
	Private aColunas := {}

	Default nOper := 5
	//Campos da Tempor�ria
	aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marca��o
	aAdd(aCampos, { "PLAN" , "C", 30, 0 })
	//aAdd(aCampos, { "DESCTP", "C", 25,  0 })
	aAdd(aCampos, { "QTD", "N", 5,  0 })
	aAdd(aCampos, { "TOT_PEND", "C", 15,  0 })
	aAdd(aCampos, { "TOT_APROV", "C", 15,  0 })
	aAdd(aCampos, { "TOT_REJEIT", "C", 15,  0 })
	aAdd(aCampos, { "TOT_PLAN", "C", 15,  0 })

	//Cria a tabela tempor�ria
	oTempTable:= FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaCols2()

	//Popula a tabela tempor�ria
	Processa({|| fPopula2(aTelaG)}, "Processando...")

	//Cria a janela
	DEFINE MSDIALOG oDlgPulo TITLE "Relat�rio Repasse/Honorario"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL


	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de t�tulo, a superior e a do calend�rio
	oFWLayer:addLine("TIT", 15, .F.)
	oFWLayer:addLine("COR", 90, .F.)

	//Adicionando as colunas das linhas
	oFWLayer:addCollumn("HEADERTEXT",   060, .T., "TIT")
	oFWLayer:addCollumn("BTNOK",     	100, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR",      100, .T., "TIT")
	oFWLayer:addCollumn("COLGRID",      100, .T., "COR")

	//Criando os paineis
	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNOK",      "TIT")
	oPanGrid   := oFWLayer:GetColPanel("COLGRID",    "COR")

	//T�tulos e SubT�tulos
	oSayModulo := TSay():New(004, 008, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 100, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 100, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os bot�es
	oBtnSair := TButton():New(006, 9, "Gerar Excel",             oPanSair, {|| RptStatus({|| fExcel(aTelaG,cAliasTmp)}, "Aguarde...", "Processando..."),oDlgPulo:End(),lPosTela := .T.}, 70, 018, , oFontBtn, , .T., , , , , , )
	oBtnSair := TButton():New(006, 80, "Cancelar",             oPanSair, {|| oDlgPulo:End()}, 70, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWMarkBrowse():New()
	oGetGrid:SetDataTable()
	//oGetGrid:SetInsert(.F.)
	//oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp)
	oGetGrid:DisableReport()
	oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFieldMark('OK')
	oGetGrid:SetFontBrowse(oFontSay)
	oGetGrid:SetColumns(aColunas)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:SetCustomMarkRec({ || fOk(oGetGrid) })
	oGetGrid:Activate()
	Activate MsDialog oDlgPulo Centered
	oTempTable:Delete()
Return

Static Function fPopula2(aTelag)

	Local nQtPlan := 0
	Local nTotPlan := 0
	Local cPlanilhas := ""
	Local aPlanilhas := {}
	Local nX := 0
	Local nY := 0
	Local nZ := 0
	Local aResult := {}
	Local aTot := {}

	For nX := 1 To Len(aTelag)

		If !(AllTrim(aTelaG[nX][01]) $ AllTrim(cPlanilhas))
			If nX <> Len(aTelaG)
				cPlanilhas += aTelaG[nX][01]+"|"
			Else
				cPlanilhas += aTelaG[nX][01]
			EndIf
		EndIf
	Next nX

	aPlanilhas := StrTokArr(cPlanilhas,"|")
	DBSELECTAREA("SCR")

	For nY := 01 To Len(aPlanilhas)

		For nZ := 01 To Len(aTelaG)
			SCR->(DbGoto(aTelaG[nZ][3]))
			If SCR->CR_STATUS == '02'
				If AllTrim(aPlanilhas[nY]) == AllTrim(aTelaG[nZ][1])
					nQtPlan++
					nTotPlan := nTotPlan + aTelaG[nZ][2]
				EndIf
			EndIf
		Next nZ

		aTot := fGetTot(aPlanilhas[nY])
		RecLock(cAliasTmp, .T.)
		(cAliasTmp)->OK := Space(2)
		(cAliasTmp)->PLAN := aPlanilhas[nY]
		(cAliasTmp)->TOT_PEND := AllTrim(Transform(NOROUND(nTotPlan,5), "@E 999,999.99" ))
		(cAliasTmp)->TOT_APROV := AllTrim(Transform(NOROUND(aTot[1],5), "@E 999,999.99" ))
		(cAliasTmp)->QTD := nQtP
		(cAliasTmp)->TOT_REJEIT:= AllTrim(Transform(NOROUND(aTot[2],5), "@E 999,999.99" ))
		(cAliasTmp)->TOT_PLAN := AllTrim(Transform(NOROUND(aTot[3],5), "@E 999,999.99" ))
		(cAliasTmp)->(MsUnlock())

		nQtPlan := 0

		nTotPlan := 0
	Next nY

Return

Static Function fExcel(aTelaG,cAliasTmp)
	Local aArea        := GetArea()       := ""
	Local oFWMsExcel
	Local oExcel
	Local cArquivo    := GetTempPath()+'RELFRPMED1.xml'


	//Criando o objeto que ir� gerar o conte�do do Excel
	oFWMsExcel := FWMSExcel():New()



	oFWMsExcel:AddworkSheet("Relat�rio")
	//Criando a Tabela
	oFWMsExcel:AddTable("Relat�rio","Documentos")
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Planilha",1)
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Qtd Documentos",1)
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Total Pendente",1)
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Total Aprovado",1)
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Total Rejeitado",1)
	oFWMsExcel:AddColumn("Relat�rio","Documentos","Total da planilha",1)
	//Criando as Linhas... Enquanto n�o for fim da query
	(cAliasTmp)->(DbGoTop())
	While !((cAliasTmp)->(EoF()))
		oFWMsExcel:AddRow("Relat�rio","Documentos",{;
		(cAliasTmp)->PLAN,;
		(cAliasTmp)->QTD,;
		(cAliasTmp)->TOT_PEND,;
		(cAliasTmp)->TOT_APROV,;
		(cAliasTmp)->TOT_REJEIT,;
		(cAliasTmp)->TOT_PLAN;
		})

		//Pulando Registro
		(cAliasTmp)->(DbSkip())
	EndDo

	//Ativando o arquivo e gerando o xml
	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(cArquivo)

	//Abrindo o excel e abrindo o arquivo xml
	// oExcel := MsExcel():New()             //Abre uma nova conex�o com Excel
	// oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
	// oExcel:SetVisible(.T.)                 //Visualiza a planilha
	// oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas
	ShellExecute("open",cArquivo,"","",1)	

	RestArea(aArea)
Return
