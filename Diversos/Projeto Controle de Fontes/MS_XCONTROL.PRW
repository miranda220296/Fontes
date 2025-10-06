#Include "Protheus.ch"
#Include "Totvs.ch"
#include "fileio.ch"
#INCLUDE "TopConn.ch"
#Include 'FWMVCDef.ch'

/*/{Protheus.Doc} MS_XCONTROL    
Fonte que controla todo o processo de reserva de fontes 
@author		Miranda Solution - Lucas Miranda de AGuiar
@version	P12
@since	    22/02/2025  
/*/

User Function MS_XCONTROL()
	Local aArea   := GetArea()
	Local oBrowse := NIL
	Private cTitulo := "Controle de reservas de fontes."
	Private cAlias := "MSF"

	oBrowse := FwLoadBrw("MS_XCONTROL")
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAlias)
	oBrowse:SetDescription(cTitulo)
	oBrowse:AddLegend( "MSF->MSF_STATUS == '1'", "GREEN",  "Liberado" )
	oBrowse:AddLegend( "MSF->MSF_STATUS == '2'", "WHITE",  "Reservado")
	oBrowse:AddLegend( "MSF->MSF_STATUS == '3'", "BLACK",  "Reservado divergente RPO" )
	oBrowse:AddLegend( "MSF->MSF_STATUS == '4'", "RED",    "Liberado divergente RPO" )
	oBrowse:AddLegend( "MSF->MSF_STATUS == '5'", "BLUE",    "Não compilado" )
	oBrowse:Activate()

	RestArea(aArea)


Return

Static Function MenuDef()
	Local aRot := {}

	ADD OPTION aRot TITLE 'Solicitar reserva de fonte(s)'   ACTION 'U_MSXFRES' 			 OPERATION 3 ACCESS 0
	ADD OPTION aRot TITLE 'Adicionar fonte ao projeto'  	ACTION 'U_MSXFINC' 			 OPERATION 3 ACCESS 0
	ADD OPTION aRot TITLE 'Devolver fonte'              	ACTION 'U_MSXFDEV' 			 OPERATION 3 ACCESS 0
	ADD OPTION aRot TITLE 'Cancelar reserva'            	ACTION 'U_MSXCANC' 			 OPERATION 5 ACCESS 0
	ADD OPTION aRot TITLE 'Equalização do RPO'          	ACTION 'U_MSXFEQUAL'         OPERATION 3 ACCESS 0
	ADD OPTION aRot TITLE 'Rel. Divergências'           	ACTION 'U_XXRELDIV'          OPERATION 6 ACCESS 0

Return aRot

Static Function ModelDef()
	Local oModel := Nil
	Local oStMSF := FWFormStruct(1, cAlias)


	oModel := MPFormModel():New("MSCONTR",/*bPre*/,,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("MSFONTS",/*cOwner*/,oStMSF)
	oModel:SetPrimaryKey({'MSF_FONTE','MSF_DTRES'})


	oModel:SetDescription(cTitulo)
	oModel:GetModel("MSFONTS"):SetDescription("Formulário do Cadastro "+cTitulo)

Return oModel

Static Function ViewDef()

	Local oModel := FWLoadModel("MS_XCONTROL")
	Local oStMSF := FWFormStruct(2, cAlias)
	Local oView := Nil

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_MSF", oStMSF, "MSFONTS")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_MSF', cTitulo )
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_MSF","TELA")

Return oView

User Function MSXFEQUAL(lSched)

	Local aArea := GetArea()
	Local nX    := 01
	Local cDiretorio := ""
	Local aArquivos := {}
	Local aInfoFonte := {}


	Default lSched := .F.

	cDiretorio := GetNewPar("MV_XMSFDIR","C:\teste\")

	If Empty(cDiretorio)
		Alert("O caminho do diretório não está definido! Favor validar o parâmetro MV_XMSFDIR")
		Return
	EndIf

	aArquivos := Directory(cDiretorio + "*.PRW*")

	DbSelectArea("MSF")
	MSF->(DbSetOrder(1))
	For nX := 01 To Len(aArquivos)
		aInfoFonte := GetApoInfo(Replace(AllTrim(aArquivos[nX][1]),".ZIP",""))
		If MSF->(DbSeek(Replace(PadR(aArquivos[nX][1],TamSX3("MSF_FONTE")[1]," "),".ZIP","")))
			Reclock("MSF",.F.)
			If (MSF->MSF_STATUS <> '2' .And. MSF->MSF_STATUS <> '3')
				If !Empty(aInfoFonte)
					MSF->MSF_DTRPO := aInfoFonte[4]
					MSF->MSF_HRRPO := aInfofonte[5]
					If  DtoS(MSF->MSF_DTPAST)+MSF->MSF_HRPAST == DtoS(aInfoFonte[4])+aInfofonte[5]
						MSF->MSF_STATUS := "1"
					Else
						MSF->MSF_STATUS := "4"
					EndIf
				Else
					MSF->MSF_STATUS := "5"
				EndIf
			EndIf
			If !Empty(MSF->MSF_DTRES)
				MSF->MSF_TEMPO := cValToChar(DateDiffDay(MSF->MSF_DTRES,date()))
			EndIf

			If (MSF->MSF_STATUS <> "1" .And. MSF->MSF_STATUS <> '2' .And. MSF->MSF_STATUS <> '3')
				If MSF->MSF_DTPAST == MSF->MSF_DTRPO
					If Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == 1 .Or. Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == - 1
						MSF->MSF_STATUS := "1"//Corrigir a diferença de 1 segundo, não há diferença de fonte, é um BUG do RPO.
					EndIf
				EndIf
			EndIf
			MSF->(MsUnLock())
		EndIf

	Next nX

	RestArea(aArea)
Return

User Function MSXFINC()

	Local cDirectory := ""
	Local aArquivos := {}
	Local cMainPath 	:= "C:\"
	Private oProcess 	:= Nil

	cDirectory 	:= AllTrim(cGetFile('*.prw|*.prw','Importação do arquivo Solicitação de pagamento.', 0,cMainPath, .T., GETF_MULTISELECT + GETF_LOCALHARD, .T.))
	aArquivos 	:= Separa(cDirectory, "|")

	If Len(aArquivos) > 0

		oProcess := MsNewProcess():New( { || fInclui(aArquivos) } , "Validando arquivos selecionados..." , "Aguarde..." , .F. )
		oProcess:Activate()
	Else
		Alert("Não foram selecionados arquivos para importação.")
	Endif

Return


Static function fInclui(aSel)

	Local nA := 01
	Local aInfoFonte := {}
	Local cDiretorio := GetNewPar("MV_XMSFDIR","C:\teste\")
	Local cLog := ""
	Local aArquivos := {}
	Local nZ := 0
	Local cPst := ""
	Local aPst := {}
	Local cArqLog    := "zLOGFontes" + dToS(Date()) + "_" + StrTran(Time(), ':', '-') + ".txt"

	Private cDirLog    := GetTempPath() + "x_importacao\"

	Default aSel := {}

	If ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIf

	oProcess:SetRegua1(Len(aSel))

	DbSelectArea("MSF")
	MSF->(DbSetOrder(1))

	For nA := 01 To Len(aSel)
		aArquivos := Directory(AllTrim(aSel[nA]))
		oProcess:IncRegua1("Adicionando fonte: " + AllTrim(aArquivos[1][1]))
		aInfoFonte := GetApoInfo(AllTrim(aArquivos[1][1]))
		If MSF->(DbSeek(PadR(aArquivos[1][1],TamSX3("MSF_FONTE")[1]," ")))
			If nA == 01
				cLog += "Listagem de fontes não adicionados." +CRLF
				cLog += "Os fontes abaixo já existem no projeto, por isso não podem ser adicionados por esta rotina, favor utilizar a rotina de devolução de fonte." +CRLF
			EndIf
			cLog += aArquivos[1][1] + CRLF
		Else
			//Inclusão de novo fonte
			aPsT := StrTokarr(aSel[nA],"\")
			For nZ := 01 To Len(aPst)
				If nZ == Len(aPst)
					Loop
				EndIf
				cPst += aPst[nZ]+"\"
			Next nZ

			If FZip(cDiretorio+aArquivos[1][1]+".zip",{AllTrim(aSel[nA])},AllTrim(cPst))  == 0
				cPst := ""
				Reclock("MSF",.T.)
				MSF->MSF_FONTE :=  aArquivos[1][1]
				MSF->MSF_DTPAST := aArquivos[1][3]
				MSF->MSF_HRPAST := aArquivos[1][4]
				If !Empty(aInfoFonte)
					MSF->MSF_DTRPO := aInfoFonte[4]
					MSF->MSF_HRRPO := aInfofonte[5]
					If  DtoS(aInfoFonte[4])+aInfofonte[5] == DtoS(aArquivos[1][3])+aArquivos[1][4]
						MSF->MSF_STATUS := "1"
					Else
						MSF->MSF_STATUS := "4"
					EndIf
				Else
					MSF->MSF_STATUS := "5"
				EndIf

				If MSF->MSF_STATUS <> "1"
					If MSF->MSF_DTPAST == MSF->MSF_DTRPO
						If Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == 1 .Or. Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == - 1
							MSF->MSF_STATUS := "1"//Corrigir a diferença de 1 segundo, não há diferença de fonte, é um BUG do RPO.
						EndIf
					EndIf
				EndIf
				MSF->(MsUnLock())
			Else
				Alert("Não foi possível zipar o arquivo! Favor verificar com o DEV.")
				cPst := ""
			EndIf
		EndIf
	Next nA

	If ! Empty(cLog)
		Alert("Alguns fontes não foram carregados, o LOG será exibido a seguir.")
		cLog := "Processamento finalizado, abaixo as mensagens de log: " + CRLF + cLog
		MemoWrite(cDirLog + cArqLog, cLog)
		ShellExecute("OPEN", cArqLog, "", cDirLog, 1)
	Else
		MsgInfo("Carga realizada com sucesso!","Reserva de fontes.")
	EndIf

return



User Function MSXFDEV()

	Local cDirectory := ""
	Local aArquivos := {}
	Local cMainPath 	:= "C:\"
	Private oProcess 	:= Nil

	cDirectory 	:= AllTrim(cGetFile('*.prw|*.prw','Importação do arquivo Solicitação de pagamento.', 0,cMainPath, .T., GETF_MULTISELECT + GETF_LOCALHARD, .T.))
	aArquivos 	:= Separa(cDirectory, "|")

	If Len(aArquivos) > 0

		oProcess := MsNewProcess():New( { || fDevolve(aArquivos) } , "Validando arquivos selecionados..." , "Aguarde..." , .F. )
		oProcess:Activate()
	Else
		Alert("Não foram selecionados arquivos para importação.")
	Endif

Return


Static function fDevolve(aSel)

	Local nA := 01
	Local aInfoFonte := {}
	Local cDiretorio := GetNewPar("MV_XMSFDIR","C:\teste\")
	Local cLog := ""
	Local aArquivos := {}
	Local nZ := 0
	Local cPst := ""
	Local aPst := {}
	Local aDev := {}
	Local cArqLog    := "zLOGFontes" + dToS(Date()) + "_" + StrTran(Time(), ':', '-') + ".txt"

	Private cDirLog    := GetTempPath() + "x_importacao\"

	Default aSel := {}

	If ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIf

	oProcess:SetRegua1(Len(aSel))

	DbSelectArea("MSF")
	MSF->(DbSetOrder(1))

	For nA := 01 To Len(aSel)
		aArquivos := Directory(aSel[nA])
		oProcess:IncRegua1("Adicionando fonte: " + AllTrim(aArquivos[1][1]))
		aInfoFonte := GetApoInfo(AllTrim(aArquivos[1][1]))
		If !MSF->(DbSeek(PadR(aArquivos[1][1],TamSX3("MSF_FONTE")[1]," ")))
			If nA == 01
				cLog += "Listagem de fontes não adicionados." +CRLF
			EndIf
			cLog += aArquivos[1][1] + " - O fonte não existe no projeto, e não pode ser devolvido por esta rotina. Favor utilizar a rotina de inclusão de fonte. "+CRLF
		Else
			//Inclusão de novo fonte
			If Alltrim(UsrRetName(__cUserID)+"_"+__cUserID) == Alltrim(MSF->MSF_NOMER)
				aPsT := StrTokarr(aSel[nA],"\")
				For nZ := 01 To Len(aPst)
					If nZ == Len(aPst)
						Loop
					EndIf
					cPst += aPst[nZ]+"\"
				Next nZ1
				aDev := Directory(cDiretorio+aArquivos[1][1]+"_BACKUP.zip")
				If !Empty(aDev)
					FErase(cDiretorio+aArquivos[1][1]+"_BACKUP.zip")
				EndIf
				If FRename(cDiretorio+aArquivos[1][1]+".zip", cDiretorio+aArquivos[1][1]+"_BACKUP.zip") == 0
					If FZip(cDiretorio+aArquivos[1][1]+".zip",{AllTrim(aSel[nA])},AllTrim(cPst))  == 0
						cPst := ""
						Reclock("MSF",.F.)
						MSF->MSF_FONTE :=  aArquivos[1][1]
						MSF->MSF_DTPAST := aArquivos[1][3]
						MSF->MSF_HRPAST := aArquivos[1][4]
						MSF->MSF_ULTR := MSF->MSF_DTRES
						MSF->MSF_DTRES := StoD(" ")
						MSF->MSF_ULTE := Date()
						MSF->MSF_ULTU := MSF->MSF_NOMER
						MSF->MSF_TEMPO := ""
						MSF->MSF_NOMER := ""
						If !Empty(aInfoFonte)
							MSF->MSF_DTRPO := aInfoFonte[4]
							MSF->MSF_HRRPO := aInfofonte[5]
							If  DtoS(aInfoFonte[4])+aInfofonte[5] == DtoS(aArquivos[1][3])+aArquivos[1][4]
								MSF->MSF_STATUS := "1"
							Else
								MSF->MSF_STATUS := "4"
							EndIf
						Else
							MSF->MSF_STATUS := "5"
						EndIf

						If MSF->MSF_STATUS <> "1"
							If MSF->MSF_DTPAST == MSF->MSF_DTRPO
								If Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == 1 .Or. Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == - 1
									MSF->MSF_STATUS := "1"//Corrigir a diferença de 1 segundo, não há diferença de fonte, é um BUG do RPO.
								EndIf
							EndIf
						EndIf
						MSF->(MsUnLock())
					Else
						Alert("Não foi possível zipar o arquivo! Favor verificar com o DEV.")
						cPst := ""
					EndIf
				Else
					Alert("Não foi possível renomear o arquivo! Favor verificar com o DEV.")
				EndIf
			Else
				If Empty(MSF->MSF_NOMER)
					cLog += "O fonte " + aArquivos[1][1] + " não está reservado, você não poderá realizar a devolução!"+CRLF
				Else
					cLog += "O fonte " + aArquivos[1][1] + " está reservado com o usuário " + MSF->MSF_NOMER + " você não poderá realizar a devolução!"+CRLF
				EndIf

			EndIf
		EndIf

	Next nA

	If ! Empty(cLog)
		Alert("Alguns fontes não foram carregados, o LOG será exibido a seguir.")
		cLog := "Processamento finalizado, abaixo as mensagens de log: " + CRLF + cLog
		MemoWrite(cDirLog + cArqLog, cLog)
		ShellExecute("OPEN", cArqLog, "", cDirLog, 1)
	Else
		MsgInfo("Carga realizada com sucesso!","Reserva de fontes.")
	EndIf

return


User Function MSXFRES()

	Local nLargBtn      := 50
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabeçalho
	Private oSayModulo, cSayModulo := "Reserva de Fontes"
	Private oSayTitulo, cSayTitulo := ''
	Private oSaySubTit, cSaySubTit := ''
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := 1000
	Private nJanAltu := 600
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

	//Campos da Temporária
	aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marcação
	aAdd(aCampos, { "FONTE" , "C", 30, 0 })
	aAdd(aCampos, { "DDATA" , "C", 8, 0 })
	aAdd(aCampos, { "HORA", "C", 8,  0 })

	//Cria a tabela temporária
	oTempTable:= FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaCols()

	//Popula a tabela temporária
	Processa({|| fPopula()}, "Processando...")

	//Cria a janela
	DEFINE MSDIALOG oDlgPulo TITLE "Reserva de fontes"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de título, a superior e a do calendário
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

	//Títulos e SubTítulos
	oSayModulo := TSay():New(004, 008, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 100, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 100, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os botões
	oBtnSair := TButton():New(006, 9, "Confirmar",             oPanSair, {|| oDlgPulo:End(),lPosTela := .T.,fGetSel(cAliasTmp)}, 70, 018, , oFontBtn, , .T., , , , , , )
	oBtnSair := TButton():New(006, 80, "Cancelar",             oPanSair, {|| oDlgPulo:End()}, 70, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWMarkBrowse():New()
	oGetGrid:SetDataTable()
	oGetGrid:SetMenuDef(" ")
	//oGetGrid:SetInsert(.F.)
	//oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp)
	oGetGrid:DisableReport()
	//oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	//oGetGrid:DisableSeek()
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

Static Function fCriaCols(lCanc)
	Local nAtual   := 0
	Local aColunas := {}
	Local aEstrut  := {}
	Local oColumn

	Default lCanc := .F.

	//Adicionando campos que serão mostrados na tela
	//[1] - Campo da Temporaria
	//[2] - Titulo
	//[3] - Tipo
	//[4] - Tamanho
	//[5] - Decimais
	//[6] - Máscara
	aAdd(aEstrut, {"FONTE", "Nome do fonte",                "C", 30,   0, ""})
	aAdd(aEstrut, {"DDATA", "Data",             "C", 8,    0, ""})
	aAdd(aEstrut, {"HORA", "Hora",        "C", 8,    0, ""})

	If lCanc

		For nAtual := 1 To Len(aEstrut)
			//Cria a coluna
			oColumn := FWBrwColumn():New()
			oColumn:SetData(&("{|| (cAliasTmp2)->" + aEstrut[nAtual][1] +"}"))
			oColumn:SetTitle(aEstrut[nAtual][2])
			oColumn:SetType(aEstrut[nAtual][3])
			oColumn:SetSize(aEstrut[nAtual][4])
			oColumn:SetDecimal(aEstrut[nAtual][5])
			oColumn:SetPicture(aEstrut[nAtual][6])
			//oColumn:bHeaderClick := &("{|| fOrdena('" + aEstrut[nAtual][1] + "') }")

			//Adiciona a coluna
			aAdd(aColunas, oColumn)
		Next
	Else
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

	EndIf
Return aColunas



Static Function fPopula(lCanc)


	Local cAliasMSF := GetNextAlias()
	Local cQuery := ""
	Local cRet := ""

	Default lCanc := .F.

	If lCanc
		cQuery := " SELECT MSF_FONTE, MSF_DTPAST, MSF_HRPAST FROM "+RetSqlName("MSF")+" WHERE D_E_L_E_T_ = ' ' "
		cQuery += " AND MSF_STATUS IN ('2','3') AND MSF_NOMER = '"+Alltrim(UsrRetName(__cUserID)+"_"+__cUserID)+"'"
	Else
		cQuery := " SELECT MSF_FONTE, MSF_DTPAST, MSF_HRPAST FROM "+RetSqlName("MSF")+" WHERE D_E_L_E_T_ = ' ' "
		cQuery += " AND MSF_STATUS NOT IN ('2','3')"

	EndIf
	If Select( cAliasMSF ) > 0
		( cAliasMSF )->( DbCloseArea() )
	EndIf

	TcQuery cQuery Alias ( cAliasMSF ) New

	If lCanc
		If (cAliasMSF)->(EOF())
			cRet := "Sem Registros"
			Return cRet
		EndIf
	EndIf


	While (cAliasMSF)->(!EOF())
		If lCanc
			RecLock(cAliasTmp2, .T.)
			(cAliasTmp2)->FONTE := (cAliasMSF)->MSF_FONTE
			(cAliasTmp2)->DDATA := (cAliasMSF)->MSF_DTPAST
			(cAliasTmp2)->HORA  := (cAliasMSF)->MSF_HRPAST
			(cAliasTmp2)->(MsUnlock())
			(cAliasMSF)->(DbSKip())
		Else
			RecLock(cAliasTmp, .T.)
			(cAliasTmp)->FONTE := (cAliasMSF)->MSF_FONTE
			(cAliasTmp)->DDATA := (cAliasMSF)->MSF_DTPAST
			(cAliasTmp)->HORA  := (cAliasMSF)->MSF_HRPAST
			(cAliasTmp)->(MsUnlock())
			(cAliasMSF)->(DbSKip())
		EndIf
	EndDo
Return



Static Function fGetSel(cAliasTmp)

	Local aReservas := {}
	Local nX := 01
	Local cTemp := GetTempPatch()
	Local cDiretorio := GetNewPar("MV_XMSFDIR","C:\teste\")

	Default cAliasTmp := ""


	(cAliasTmp)->(DbGoTop())

	While (cAliasTmp)->(!EOF())

		If !Empty((cAliasTmp)->OK)
			AADD(aReservas,(cAliasTmp)->FONTE)
		EndIf

		(cAliasTmp)->(DbSkip())
	EndDo

	DbSelectArea("MSF")
	MSF->(DbSetOrder(1))
	For nX := 01 To Len(aReservas)

		cTemp := GetTempPatch()+"Reservas_Fontes"

		If ! ExistDir(cTemp)
			MakeDir(cTemp)
		EndIf

		cTemp := cTemp + "\Reserva_"+UPPER(Replace(AllTrim(aReservas[nX]),".PRW",""))+"_"+DtoS(Date())+"\"

		If ! ExistDir(cTemp)
			MakeDir(cTemp)
		EndIf

		__CopyFile(cDiretorio+AllTrim(aReservas[nX])+".ZIP", cTemp+AllTrim(aReservas[nX])+".ZIP")

		MSF->(DbSeek(aReservas[nX]))
		Reclock("MSF",.F.)
		MSF->MSF_DTRES := Date()
		MSF->MSF_NOMER := Alltrim(UsrRetName(__cUserID)+"_"+__cUserID)

		If Empty(MSF->MSF_DTRPO) .Or. (DtoS(MSF->MSF_DTPAST)+MSF->MSF_HRPAST <> DtoS(MSF->MSF_DTRPO)+MSF->MSF_HRPAST)
			MSF->MSF_STATUS := "3"
		Else
			MSF->MSF_STATUS := "2"
		EndIf

		If MSF->MSF_STATUS <> "2"
			If MSF->MSF_DTPAST == MSF->MSF_DTRPO
				If Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == 1 .Or. Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == - 1
					MSF->MSF_STATUS := "2"//Corrigir a diferença de 1 segundo, não há diferença de fonte, é um BUG do RPO.
				EndIf
			EndIf
		EndIf

	Next nX
	MsgInfo("Os fontes foram enviados para o caminho " + GetTempPatch()+"Reservas_Fontes que será aberto em instantes")
	ShellExecute("open", "explorer.exe", "Reservas_Fontes", GetTempPatch(), 1)
Return


Static Function fOk(oGrid,lCanc)

	Local aArea := {}
	Local cMark := oGetGrid:Mark()

	Default lCanc := .F.

	If lCanc
		aArea := (cAliasTmp2)->(GetArea())
		If !Empty((cAliasTmp2)->OK)
			Reclock((cAliasTmp2),.F.)
			(cAliasTmp2)->OK := ""
			(cAliasTmp2)->(MsUnLock())
		Else
			Reclock((cAliasTmp2),.F.)
			(cAliasTmp2)->OK := cMark
			(cAliasTmp2)->(MsUnLock())
		EndIf
	Else
		aArea := (cAliasTmp)->(GetArea())
		If !Empty((cAliasTmp)->OK)
			Reclock((cAliasTmp),.F.)
			(cAliasTmp)->OK := ""
			(cAliasTmp)->(MsUnLock())
		Else
			Reclock((cAliasTmp),.F.)
			(cAliasTmp)->OK := cMark
			(cAliasTmp)->(MsUnLock())
		EndIf
	EndIf
	RestArea(aArea)
Return



User Function MSXCANC()
	Local nLargBtn      := 50
	Local cRet := ""
	//Objetos e componentes
	Private oDlgPulo
	Private oFwLayer
	Private oPanTitulo
	Private oPanGrid
	//Cabeçalho
	Private oSayModulo, cSayModulo := ""
	Private oSayTitulo, cSayTitulo := 'Cancelamento da reserva'
	Private oSaySubTit, cSaySubTit := ''
	//Tamanho da janela
	Private aSize := MsAdvSize(.F.)
	Private nJanLarg := 1000
	Private nJanAltu := 600
	//Fontes
	Private cFontUti    := "Tahoma"
	Private oFontMod    := TFont():New(cFontUti, , -38)
	Private oFontSub    := TFont():New(cFontUti, , -20)
	Private oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	Private oFontBtn    := TFont():New(cFontUti, , -14)
	Private oFontSay    := TFont():New(cFontUti, , -12)
	//Grid
	Private aCampos := {}
	Private cAliasTmp2 := GetNextAlias()
	Private aColunas := {}

	//Campos da Temporária
	aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marcação
	aAdd(aCampos, { "FONTE" , "C", 30, 0 })
	aAdd(aCampos, { "DDATA" , "C", 8, 0 })
	aAdd(aCampos, { "HORA", "C", 8,  0 })

	//Cria a tabela temporária
	oTempTable:= FWTemporaryTable():New(cAliasTmp2)
	oTempTable:SetFields( aCampos )
	oTempTable:Create()

	//Busca as colunas do browse
	aColunas := fCriaCols(.T.)

	//Popula a tabela temporária
	Processa({|| cRet := fPopula(.T.)}, "Processando...")

	If !Empty(cRet)
		Alert("Você não possui reservas ativas!")
		oTempTable:Delete()
		Return
	EndIf

	//Cria a janela
	DEFINE MSDIALOG oDlgPulo TITLE "Reserva de fontes"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgPulo,.F.)

	//Adicionando 3 linhas, a de título, a superior e a do calendário
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

	//Títulos e SubTítulos
	oSayModulo := TSay():New(004, 008, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 100, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 100, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 300, 30, , , , , , .F., , )

	//Criando os botões
	oBtnSair := TButton():New(006, 9, "Confirmar",             oPanSair, {|| oDlgPulo:End(),lPosTela := .T.,fGetCanc(cAliasTmp2)}, 70, 018, , oFontBtn, , .T., , , , , , )
	oBtnSair := TButton():New(006, 80, "Cancelar",             oPanSair, {|| oDlgPulo:End()}, 70, 018, , oFontBtn, , .T., , , , , , )

	//Cria a grid
	oGetGrid := FWMarkBrowse():New()
	oGetGrid:SetDataTable()
	oGetGrid:SetMenuDef(" ")
	//oGetGrid:SetInsert(.F.)
	//oGetGrid:SetDelete(.F., { || .F. })
	oGetGrid:SetAlias(cAliasTmp2)
	oGetGrid:DisableReport()
	//oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	//oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFieldMark('OK')
	oGetGrid:SetFontBrowse(oFontSay)
	oGetGrid:SetColumns(aColunas)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:SetCustomMarkRec({ || fOk(oGetGrid,.T.) })
	oGetGrid:Activate()
	Activate MsDialog oDlgPulo Centered
	oTempTable:Delete()
Return

Static Function fGetCanc(cAliasTmp2)

	Default cAliasTmp := ""

	DbSelectArea("MSF")
	MSF->(DbSetOrder(1))
	(cAliasTmp2)->(DbGoTop())
	While (cAliasTmp2)->(!EOF())
		If !Empty((cAliasTmp2)->OK)
			MSF->(DbSeek((cAliasTmp2)->FONTE))
			Reclock("MSF",.F.)
			MSF->MSF_NOMER := ""
			MSF->MSF_DTRES := StoD(" ")
			MSF->MSF_TEMPO := " "
			If !Empty(MSF->MSF_DTRPO)
				If  DtoS(MSF->MSF_DTPAST)+MSF->MSF_HRPAST == DtoS(MSF->MSF_DTRPO)+MSF->MSF_HRRPO
					MSF->MSF_STATUS := "1"
				Else
					MSF->MSF_STATUS := "4"
				EndIf
			Else
				MSF->MSF_STATUS := "5"
			EndIf
			If MSF->MSF_STATUS <> "1"
				If MSF->MSF_DTPAST == MSF->MSF_DTRPO
					If Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == 1 .Or. Val(SUBSTR(MSF->MSF_HRPAST,7,2)) - Val(SUBSTR(MSF->MSF_HRRPO,7,2)) == - 1
						MSF->MSF_STATUS := "1"//Corrigir a diferença de 1 segundo, não há diferença de fonte, é um BUG do RPO.
					EndIf
				EndIf
			EndIf
			MSF->(MsUnlock())
		EndIf
		(cAliasTmp2)->(DbSkip())
	EndDo
	MsgInfo("Cancelamento de reserva realizado com sucesso!","Controle de reservas.")
Return


User Function XXRELDIV()

	Local cQry := ""
	Local cTmpTbl := GetNextAlias()

	cQry := " SELECT MSF_FONTE,MSF_DTPAST,MSF_HRPAST,MSF_DTRPO,MSF_HRRPO,MSF_NOMER,MSF_STATUS,MSF_ULTE,MSF_ULTU "
	cQry += " FROM " + RetSqlName("MSF") + " WHERE D_E_L_E_T_ = ' ' AND MSF_STATUS IN ('3','4','5') "

	TcQuery cQry Alias ( cTmpTbl ) New

	//Criando o objeto que irá gerar o conteúdo do Excel
	oFWMsExcel := FWMSExcel():New()

	oFWMsExcel:AddworkSheet("Divergentes")
	oFWMsExcel:AddworkSheet("Não Compilados")

	//Criando a Tabelas
	oFWMsExcel:AddTable("Divergentes","Divergentes")
	oFWMsExcel:AddTable("Não Compilados","Não Compilados")


	//Criando colunas tabela 1
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Nome do fonte",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Data/Hora Pasta",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Data/Hora RPO",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Reservado?",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Reservante",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Ultima Entrega",1)
	oFWMsExcel:AddColumn("Divergentes","Divergentes","Reservante Ult Entrega",1)


	//Criando colunas tabela 2
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Nome do fonte",1)
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Data/Hora Pasta",1)
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Reservado?",1)
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Reservante",1)
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Ultima Entrega",1)
	oFWMsExcel:AddColumn("Não Compilados","Não Compilados","Reservante Ult Entrega",1)


	(cTmpTbl)->(DbGoTop())

	While !( cTmpTbl )->( Eof() )

		If ( cTmpTbl )->MSF_STATUS == "5"
			If (cTmpTbl)->MSF_STATUS == "3"
				cStatus := "Sim"
			Else
				cStatus := "Não"
			EndIf
			oFWMsExcel:AddRow("Não Compilados","Não Compilados",{;
				(cTmpTbl)->MSF_FONTE,;
				(cTmpTbl)->MSF_DTPAST + " " + (cTmpTbl)->MSF_HRPAST,;
				cStatus,;
				(cTmpTbl)->MSF_NOMER,;
				(cTmpTbl)->MSF_ULTE,;
				(cTmpTbl)->MSF_ULTU;
				})
		Else
			If (cTmpTbl)->MSF_STATUS == "3"
				cStatus := "Sim"
			Else
				cStatus := "Não"
			EndIf
			oFWMsExcel:AddRow("Divergentes","Divergentes",{;
				(cTmpTbl)->MSF_FONTE,;
				(cTmpTbl)->MSF_DTPAST + " " + (cTmpTbl)->MSF_HRPAST,;
				(cTmpTbl)->MSF_DTRPO + " " + (cTmpTbl)->MSF_HRRPO,;
				cStatus,;
				(cTmpTbl)->MSF_NOMER,;
				(cTmpTbl)->MSF_ULTE,;
				(cTmpTbl)->MSF_ULTU;
				})

		EndIf
		(cTmpTbl)->(DbSkip())
	EndDo

	(cTmpTbl)->(DBCLOSEAREA())


	//Ativando o arquivo e gerando o xml
	cArquivo    := GetTempPath()+'Rel_Divergencias_fontes' +__cUserID+DtoS(Date())+'.xml'

	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(cArquivo)

	//Abrindo o excel e abrindo o arquivo xml
	oExcel := MsExcel():New()             //Abre uma nova conexão com Excel
	oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
	oExcel:SetVisible(.T.)                 //Visualiza a planilha
	oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas


Return
