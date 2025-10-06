#INCLUDE "DIRECTRY.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE 'FWMVCDEF.CH'
#DEFINE MODEL_OPERATION_VIEW 1
#DEFINE MODEL_OPERATION_INSERT 3
#DEFINE MODEL_OPERATION_UPDATE 4
#DEFINE MODEL_OPERATION_DELETE 5
#DEFINE MODEL_OPERATION_ONLYUPDATE 6
Static CDIRTMP := GetTempPath()
/*/{Protheus.doc} RHDIVE04

	Efetua a importa��o da SRA - Diversidade

	@type Function User
	@author Cleiton Genuino da Silva
	@since 28/11/2023
	@version 12.1.2210
	@Obs.
	
		Se campo RA_FILIAL + RA_MAT  - Chave
		
		Se encontrou e est� vazio:
			
			gravar os dados da tabela enviada
		
			SRA->RA_XGENERO
			SRA->RA_XNAMESO
			SRA->RA_XUSASOC


/*/
User Function RHDIVE04()
	Local aArea                       := GetArea()
	Local nJanAltu                    := 180
	Local nJanLarg                    := 650
	Local oBtnArq
	Local oBtnImp
	Local oBtnObri
	Local oBtnSair
	Local oGrpAco
	Local oGrpPar
	Private aIteTip                   := {}
	Private oDlgPvt
	Private oSayArq, oGetArq, cGetArq := Space(400)
	Private oSayCar, oGetCar, cGetCar := ';'
	Private oSayTip, oCmbTip, cCmbTip := ""

	//Dimens�es da janela
	//Objetos da tela
	//Inserindo as op��es dispon�veis no Carga Dados Gen�rico
	aIteTip := {;
		"01=Diversidade",;
		}
	cCmbTip := aIteTip[1]

	//Criando a janela
	DEFINE MSDIALOG oDlgPvt TITLE "Carga Dados - Gen�rico" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
	//Grupo Par�metros
	@ 003, 003 	GROUP oGrpPar TO 060, (nJanLarg/2) 	PROMPT "Par�metros: " 		OF oDlgPvt COLOR 0, 16777215 PIXEL
	//Caminho do arquivo
	@ 013, 006 SAY        oSayArq PROMPT "Arquivo:"                  SIZE 060, 007 OF oDlgPvt PIXEL
	@ 010, 070 MSGET      oGetArq VAR    cGetArq                     SIZE 240, 010 OF oDlgPvt PIXEL
	oGetArq:bHelp := {||	ShowHelpCpo(	"cGetArq",;
		{"Arquivo CSV ou TXT que ser� importado."+CRLF+"Exemplo: C:\teste.CSV"},2,;
		{},2)}
	@ 010, 311 BUTTON oBtnArq PROMPT "..."      SIZE 008, 011 OF oDlgPvt ACTION (fPegaArq()) PIXEL

	//Tipo de Importa��o
	@ 028, 006 SAY        oSayTip PROMPT "Tipo Importa��o:"          SIZE 060, 007 OF oDlgPvt PIXEL
	@ 025, 070 MSCOMBOBOX oCmbTip VAR    cCmbTip ITEMS aIteTip       SIZE 100, 010 OF oDlgPvt PIXEL
	oCmbTip:bHelp := {||	ShowHelpCpo(	"cCmpTip",;
		{"Tipo de Importa��o que ser� processada."+CRLF+"Exemplo: 1 = Diversidade"},2,;
		{},2)}

	//Caracter de Separa��o do CSV
	@ 043, 006 SAY        oSayCar PROMPT "Carac.Sep.:"               SIZE 060, 007 OF oDlgPvt PIXEL
	@ 040, 070 MSGET      oGetCar VAR    cGetCar                     SIZE 030, 010 OF oDlgPvt PIXEL VALID fVldCarac()
	oGetArq:bHelp := {||	ShowHelpCpo(	"cGetCar",;
		{"Caracter de separa��o no arquivo."+CRLF+"Exemplo: ';'"},2,;
		{},2)}

	//Grupo A��es
	@ 063, 003 	GROUP oGrpAco TO (nJanAltu/2)-3, (nJanLarg/2) 	PROMPT "A��es: " 		OF oDlgPvt COLOR 0, 16777215 PIXEL

	//Bot�es
	@ 070, (nJanLarg/2)-(63*1)  BUTTON oBtnSair PROMPT "Sair"              SIZE 60, 014 OF oDlgPvt ACTION (oDlgPvt:End()) PIXEL
	@ 070, (nJanLarg/2)-(63*2)  BUTTON oBtnImp  PROMPT "Importar"      	   SIZE 60, 014 OF oDlgPvt ACTION (Processa({|| fConfirm(1) }, "Aguarde...")) PIXEL
	@ 070, (nJanLarg/2)-(63*3)  BUTTON oBtnObri PROMPT "Camp.Estrutura"    SIZE 60, 014 OF oDlgPvt ACTION (Processa({|| fConfirm(3) }, "Aguarde...")) PIXEL
	ACTIVATE MSDIALOG oDlgPvt CENTERED

	RestArea(aArea)
Return
/*/{Protheus.doc} fVldCarac
	Fun��o que valida o caracter de separa��o digitado
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fVldCarac()
	Local cInvalid := " './\"+' "'
	Local lRet     := .T.

	//Se o caracter estiver contido nos que n�o podem, retorna erro
	If cGetCar $ cInvalid
		lRet := .F.
		MsgAlert("Caracter inv�lido, ele n�o estar contido em <b>"+cInvalid+"</b>!", "Aten��o")
	EndIf
Return lRet
/*/{Protheus.doc} fPegaArq
	Fun��o respons�vel por pegar o arquivo de importa��o
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fPegaArq()
	Local cArqAux := ""
	cArqAux := cGetFile( "Arquivo Texto | *.csv",; 	// M�scara
	"Arquivo...",; 									// T�tulo
	,; 												// N�mero da m�scara
	,; 												// Diret�rio Inicial
	.F.,; 											// .F. == Abrir; .T. == Salvar
	GETF_LOCALHARD,; 								// Diret�rio full. Ex.: 'C:\TOTVS\arquivo.csv'
	.F.) 											// N�o exibe diret�rio do servidor

	//Caso o arquivo n�o exista ou estiver em branco ou n�o for a extens�o txt
	If Empty(cArqAux) .Or. !File(cArqAux) .Or. (SubStr(cArqAux, RAt('.', cArqAux)+1, 3) != "txt" .And. SubStr(cArqAux, RAt('.', cArqAux)+1, 3) != "csv")
		MsgStop("Arquivo <b>inv�lido</b>!", "Aten��o")

		//Sen�o, define o get
	Else
		cGetArq := PadR(cArqAux, len(cArqAux))
		oGetArq:Refresh()
	EndIf

Return
/*/{Protheus.doc} fConfirm
	Fun��o de confirma��o da tela principal
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fConfirm(nTipo)
	Local aAux         := {}
	Local aHead        := {}
	Local aOriginal    := {}
	Local aTabela      := {}
	Local aUnic        := {}
	Local cAux         := ""
	Local cFunBkp      := FunName()
	Local cMsg         := ""
	Local nAux         := 0
	Local nModBkp      := nModulo
	Local nX           := 0
	Local oFile        := Nil
	Private aAI0Auto   := {}
	Private aCampos    := {}
	Private aDBStruct  := {}
	Private aHeadImp   := {}
	Private aRotina    := {}
	Private aStruTmp   := {}
	Private cAliasTmp  := ""
	Private cCampoChv  := ""
	Private cCampTipo  := ""
	Private cChvUnic   := ""
	Private cFiles
	Private cFilialTab := ""
	Private cLinhaCab  := ""
	Private cMark      := "OK"
	Private cRotina    := ""
	Private cTabela    := ""
	Private lChvProt   := .F.
	Private lFilProt   := .F.
	Private nTotalReg  := 0
	Private oBrowChk
	Private oModel     := Nil
	Default nTipo      := 2

	If cCmbTip == "01"
		cTabela    := "SRA"
		cCampoChv  := ""
		cChvUnic   := Posicione("SIX",1, cTabela + cValToChar( 1 ) ,"CHAVE")
		cFilialTab := FWxFilial(cTabela)
		nModulo    := 7
		aTabela  := (cTabela)->(DBStruct())

		For nX:=1 to len(aTabela)
			If Alltrim(aTabela[nX][1]) $ 'RA_FILIAL|RA_MAT|RA_XGENERO|RA_XNAMESO|RA_XUSASOC|RA_XCODRAC'
				AADD(aDBStruct,{aTabela[nX][1],aTabela[nX][2],aTabela[nX][3],aTabela[nX][4]} )
			EndIf
		Next

	Else
		nModulo	:= nModBkp
		MsgStop("Op��o <b>Inv�lida</b>!", "Aten��o")
		Return
	EndIf

	//Importa��o dos dados
	If nTipo == 1
		//Se o arquivo existir
		oFile := FwFileReader():New(cGetArq)

		If File(cGetArq) .And.  oFile:Open()

			aOriginal := oFile:GetAllLines() // ACESSA TODAS AS LINHAS

			nTotalReg := len(aOriginal) // TOTAL DE LINHAS

			If nTotalReg <= 0
				MsgAlert("Arquivo inv�lido, n�o possui cabe�alho ou est� vazio <b>0</b> linhas!", "Aten��o")
				//Se o total de registros for menor que 2, arquivo inv�lido
			ElseIf nTotalReg < 2
				MsgAlert("Arquivo inv�lido, possui menos que <b>2</b> linhas!", "Aten��o")
				//Sen�o, chama a tela de observa��o e depois a importa��o
			Else
				//Pegando o cabe�alho
				cLinhaCab := aOriginal[1]

				aHead     := StrTokArr2(cLinhaCab, ";")
				nTotalReg := ( nTotalReg - 1 ) // Retirando o cabe�alho para correto contador de registros
				//Pegando os itens
				ADel(aOriginal, 1)
				ASize(aOriginal, Len(aOriginal) - 1)

				//Monta tabela tempor�ria
				cAliasTmp 		:= fMontaTmp()
				cObrigatorio 	:= fObrigat(.F.)

				cLinhaCab := Iif(SubStr(cLinhaCab, Len(cLinhaCab)-1, 1) == ";", SubStr(cLinhaCab, 1, Len(cLinhaCab)-1), cLinhaCab)
				aAux  := Separa(UPPER(cLinhaCab), cGetCar)
				aUnic := Separa(UPPER(cObrigatorio),cGetCar)

				//Percorrendo o aAux e adicionando no array
				For nAux := 1 To Len(aAux)
					cAux := GetSX3Cache(aAux[nAux], 'X3_TIPO')

					//Se o t�tulo estiver em branco, quer dizer que o campo n�o existe, ent�o � um campo reservado do execauto (como o LINPOS)
					If Empty(GetSX3Cache(aAux[nAux], 'X3_TITULO'))
						cCampTipo += aAux[nAux]+";"
					EndIf

					//Adiciona na grid
					aAdd(aHeadImp, { 						  aAux[nAux],; //Campo
					Iif(Empty(cAux), ' ' , cAux),; //Tipo
					.F.})  //Exclu�do
				Next

				For nAux := 1 To Len(aUnic) // Valida se os campos obrigatorios n�o est�o presentes no arquivo importado

					If ! ( aScan( aAux , aUnic[nAux] ) > 0 )
						FWAlertError('<font color="#0F0F00" size="50">Falta campos obrigat�rios !!</font>' ,"Baixe o modelo da planilha ou txt contendo os campos obrigat�rios necess�rios")
						fObrigat()
						Return .F.
					EndIf

				Next

				For nAux := 1 To Len(aAux) // Valida se os campos enviados n�o est�o presentes no dicionarios de dados

					If aScan( aDBStruct, { |x| AllTrim( x[1] ) ==  Alltrim(aAux[nAux]) } )  <= 0
						cMsg +=  aAux[nAux] + cGetCar
					EndIf

				Next

				If fValCamp(cMsg) //Se campos foram passados no arquivo mas n�o existem no dicion�rio

					//Chama a rotina de importa��o
					fImport(aOriginal)

					//Se houve erros na rotina
					(cAliasTmp)->(DbGoTop())
					If ! (cAliasTmp)->(EoF())
						fTelaErro()

						//Sen�o, mostra mensagem de sucesso
					Else

						fOkImport(aOriginal)
						FWAlertSuccess("Importa��o finalizada com Sucesso!", "Aten��o")

					EndIf
				EndIf

				//Fechando a tabela e excluindo o arquivo tempor�rio
				(cAliasTmp)->(DbCloseArea())
				fErase(cAliasTmp + GetDBExtension())
			EndIf

			//Sen�o, mostra erro
		Else
			MsgAlert("Arquivo inv�lido / n�o encontrado!", "Aten��o")
		EndIf

	ElseIf nTipo == 3
		fCriar()
	EndIf

	nModulo := nModBkp
	SetFunName(cFunBkp)

	FREEOBJ(oFile)

Return
/*/{Protheus.doc} fObrigat
	Fun��o que gera os campos obrigat�rios em CSV / TXT
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fObrigat(lTela)
	Local aArea     := GetArea()
	Local cArquivo  := "obrigatorio."
	Local cFieldMy  := SuperGetMV("CG_MYFIELD", .T. , "RA_FILIAL|RA_MAT|RA_XGENERO|RA_XNAMESO|RA_XUSASOC|RA_XCODRAC" ) // Campo n�o � obrigatorio mas tem que ser importado
	Local cCaminho  := ""
	Local cConteud  := ""
	Local nAux      := 0
	Local cExtensao := ""
	Default lTela   := .T.

	cCaminho  := CDIRTMP

	//Enquanto houver registros na SX3 e for a mesma tabela
	For nAux := 1 To Len(aDBStruct) //Se o campo for obrigat�rio

		If lTela

			//If  X3Obrigat(aDBStruct[nAux][1]) .Or. ( aDBStruct[nAux][1] $ cChvUnic )  .Or. ( aDBStruct[nAux][1] $ cFieldMy )
			If  X3Obrigat(aDBStruct[nAux][1]) .Or. aDBStruct[nAux][1] $ cFieldMy
				cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
			EndIf

		Else

			If  ( X3Obrigat(aDBStruct[nAux][1])  ) .Or. ( aDBStruct[nAux][1] $ cChvUnic )  .Or. ( aDBStruct[nAux][1] $ cFieldMy )

				//Se for o campo filial
				If '_FILIAL' $ aDBStruct[nAux][1]
					//Se a filial for conforme o protheus
					If  lFilProt
						cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
					EndIf
				ELSEIf Alltrim(aDBStruct[nAux][1]) $ Alltrim(cCampoChv)
					//Se a chave for conforme o protheus
					If  lChvProt
						cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
					EndIf
				ELSE
					cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
				EndIf

			EndIf

		EndIf

	Next nAux

	cConteud := Iif(!Empty(cConteud), SubStr(cConteud, 1, Len(cConteud)-1), "")

	If lTela

		//Se escolher csv
		If MsgYesNo("Deseja gerar o layout na extens�o <b>csv</b>?", "Aten��o")
			cExtensao := "csv"

			//Sen�o, ser� csv
		ElseIf MsgYesNo("Deseja gerar o layout na extens�o <b>txt</b>?", "Aten��o")
			cExtensao := "txt"
		EndIf
		//Gera o arquivo
		MemoWrite(cCaminho+cArquivo+cExtensao, cConteud)

		//Tentando abrir o arquivo
		nRet := ShellExecute("open", cArquivo+cExtensao, "", cCaminho, 1)

		//Se houver algum erro
		If nRet <= 32
			MsgStop("N�o foi poss�vel abrir o arquivo <b>"+cCaminho+cArquivo+cExtensao+"</b>!", "Aten��o")
		EndIf

	EndIf

	RestArea(aArea)

Return cConteud

/*/{Protheus.doc} fCriar
	Fun��o que gera os campos n�o encontrados no dicionario de dados em CSV / TXT
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fCriar(lTela)
	Local aArea     := GetArea()
	Local cArquivo  := "estrutura."
	Local cCaminho  := ""
	Local cConteud  := ""
	Local nAux      := 0
	Local cExtensao := ""
	Default lTela   := .T.

	cCaminho  := CDIRTMP

	//Enquanto houver registros na SX3 e for a mesma tabela
	For nAux := 1 To Len(aDBStruct) //Se o campo for obrigat�rio

		//Se for o campo filial
		If '_FILIAL' $ aDBStruct[nAux][1]
			//Se a filial for conforme o protheus
			If ! lFilProt
				cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
			EndIf
		ELSEIf  Alltrim(aDBStruct[nAux][1]) $ Alltrim(cCampoChv)
			//Se a chave for conforme o protheus
			If ! lChvProt
				cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
			EndIf
		ELSE
			cConteud += Alltrim(aDBStruct[nAux][1])+cGetCar
		EndIf

	Next

	cConteud := Iif(!Empty(cConteud), SubStr(cConteud, 1, Len(cConteud)-1), "")

	If lTela

		//Se escolher txt
		If MsgYesNo(" Deseja gerar o arquivo de estrutura com a extens�o <b>txt</b>?", "Aten��o")
			cExtensao := "txt"

			//Sen�o, ser� csv
		Else
			cExtensao := "csv"
		EndIf
		//Gera o arquivo
		MemoWrite(cCaminho+cArquivo+cExtensao, cConteud)

		//Tentando abrir o arquivo
		nRet := ShellExecute("open", cArquivo+cExtensao, "", cCaminho, 1)

		//Se houver algum erro
		If nRet <= 32
			MsgStop("N�o foi poss�vel abrir o arquivo <b>"+cCaminho+cArquivo+cExtensao+"</b>!", "Aten��o")
		EndIf

	EndIf

	RestArea(aArea)

Return cConteud
/*/{Protheus.doc} fValCamp
	Fun��o que gera os campos n�o encontrados no dicionario de dados e presentes no CSV / TXT
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fValCamp(cMsg)
	Local aArea     := GetArea()
	Local cArquivo  := "dicionario."
	Local cCaminho  := ""
	Local cConteud  := ""
	Local cExtensao := ""
	Default cMsg    := ""

	cCaminho  := CDIRTMP

	If !Empty(cMsg)

		cConteud := cMsg
		FWAlertError('<font color="#0F0F00" size="40">Campo(s) n�o encontrado(s) no dicionario !!</font>' ,"Crie o campo no dicon�rio ou retire o campo do arquivo")

		//Se escolher txt
		If MsgYesNo(" Deseja gerar o arquivo de campo(s) n�o encontrado(s) no dicionario <b>txt</b>?", "Aten��o")
			cExtensao := "txt"

			//Sen�o, ser� csv
		Else
			cExtensao := "csv"
		EndIf
		//Gera o arquivo
		MemoWrite(cCaminho+cArquivo+cExtensao, cConteud)

		//Tentando abrir o arquivo
		nRet := ShellExecute("open", cArquivo+cExtensao, "", cCaminho, 1)

		//Se houver algum erro
		If nRet <= 32
			MsgStop("N�o foi poss�vel abrir o arquivo <b>"+cCaminho+cArquivo+cExtensao+"</b>!", "Aten��o")
		EndIf

	EndIf

	RestArea(aArea)

Return  IIF(EMPTY(cConteud),.T.,.F.)
/*/{Protheus.doc} fMontaTmp
	Fun��o que monta a estrutura da tabela tempor�ria com os erros
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fMontaTmp()
	Local aArea     := GetArea()
	Local aIndex    := {}
	Local aStruTmp  := {}
	Local cAliasTmp := ""
	Local oTrb      := nil

	//Se tiver aberto a tempor�ria, fecha e exclui o arquivo
	If Select(cAliasTmp) > 0 .And. !Empty(cAliasTmp)
		(cAliasTmp)->(DbCloseArea())
	EndIf

	//Adicionando a Estrutura (Campo, Tipo, Tamanho, Decimal)
	aStruTmp:={}
	aadd(aStruTmp, {"TMP_ARQ"  , "C", 250, 0})
	aadd(aStruTmp, {"TMP_LINHA", "N", 018, 0})
	aadd(aStruTmp, {"TMP_SEQ"  , "C", 010, 0})

	//Criando tabela tempor�ria
	cAliasTmp := GetNextAlias()
	xCriaTRB(aStruTmp,aIndex,@oTrb,@cAliasTmp)
	cAliasTmp := oTrb:GetAlias()

	//Setando os campos que ser�o mostrados no MsSelect
	aCampos := {}
	aadd(aCampos, {"TMP_ARQ"  , , "Arquivo Log.", ""})
	aadd(aCampos, {"TMP_LINHA", , "Linha Erro"  , ""})
	aadd(aCampos, {"TMP_SEQ"  , , "Sequencia"   , "@!"})

	RestArea(aArea)

Return cAliasTmp
/*/{Protheus.doc} SraTp
	Valida��o do campo Tipo na tela de observa��o da carga gen�rica
	@type function
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 1.0
	@return LOGICAL, Retorno da rotina
/*/
User Function SraTp()
	Local lRetorn := .F.
	Local aColsAux := oMsNew:aCols
	Local nLinAtu := oMsNew:nAt

	//Se o campo atual estiver contido nos campos pr�prios do execauto (como LINPOS)
	If aColsAux[nLinAtu][01] $ cCampTipo
		lRetorn := .T.

		//Sen�o, campo n�o pode ser alterado
	Else
		lRetorn := .F.
		MsgAlert("Campo n�o pode ser alterado!", "Aten��o")
	EndIf

Return lRetorn
/*/{Protheus.doc} fTelaErro
	Fun��o que mostra os erros gerados na tela
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fTelaErro()
	Local aArea		:= GetArea()
	Local oDlgErro
	Local oGrpErr
	Local oGrpAco
	Local oBtnFech
	Local oBtnVisu
	Local nJanLarErr	:= 600
	Local nJanAltErr	:= 400
	//Criando a Janela
	DEFINE MSDIALOG oDlgErro TITLE "Erros na Importa��o" FROM 000, 000  TO nJanAltErr, nJanLarErr COLORS 0, 16777215 PIXEL
	//Grupo Erros
	@ 003, 003 	GROUP oGrpErr TO (nJanAltErr/2)-28, (nJanLarErr/2) 	PROMPT "Erros: " 		OF oDlgErro COLOR 0, 16777215 PIXEL
	//Criando o MsSelect
	oBrowChk := MsSelect():New(	cAliasTmp,;												//cAlias
	"",;														//cCampo
	,;															//cCpo
	aCampos,;													//aCampos
	,;															//lInv
	,;															//cMar
	{010, 006, (nJanAltErr/2)-31, (nJanLarErr/2)-3},;	//aCord
	,;															//cTopFun
	,;															//cBotFun
	oDlgErro,;													//oWnd
	,;															//uPar11
	)															//aColors
	oBrowChk:oBrowse:lHasMark    := .F.
	oBrowChk:oBrowse:lCanAllmark := .F.

	//Grupo A��es
	@ (nJanAltErr/2)-25, 003 	GROUP oGrpAco TO (nJanAltErr/2)-3, (nJanLarErr/2) 	PROMPT "A��es: " 		OF oDlgErro COLOR 0, 16777215 PIXEL

	//Bot�es
	@ (nJanAltErr/2)-18, (nJanLarErr/2)-(63*1)  BUTTON oBtnFech PROMPT "Fechar"        SIZE 60, 014 OF oDlgErro ACTION (oDlgErro:End()) PIXEL
	@ (nJanAltErr/2)-18, (nJanLarErr/2)-(63*2)  BUTTON oBtnVisu PROMPT "Vis.Erro"      SIZE 60, 014 OF oDlgErro ACTION (fVisErro()) PIXEL
	ACTIVATE MSDIALOG oDlgErro CENTERED

	RestArea(aArea)
Return

/*/{Protheus.doc} fVisErro
	Fun��o que visualiza o erro conforme registro posicionado
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fVisErro()
	Local nRet := 0
	Local cNomeArq := Alltrim((cAliasTmp)->TMP_ARQ)
	//Tentando abrir o objeto
	nRet := ShellExecute("open", cNomeArq, "", cDirTmp, 1)

	//Se houver algum erro
	If nRet <= 32
		MsgStop("N�o foi poss�vel abrir o arquivo " +cDirTmp+cNomeArq+ "!", "Aten��o")
	EndIf
Return

/*/{Protheus.doc} fVisPlan
	Fun��o que visualiza os erros em formato .csv
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fVisPlan()
	Local nRet := 0
	Local cNomeArq := Alltrim(cCmbTip+"Erro.csv")
	//Tentando abrir o objeto
	nRet := ShellExecute("open", cNomeArq , "", cDirTmp, 1)

	//Se houver algum erro
	If nRet <= 32
		MsgStop("N�o foi poss�vel abrir o arquivo " +cDirTmp+cNomeArq+ "!", "Aten��o")
	EndIf
Return

/*/{Protheus.doc} xCriaTRB
	Fun��o auxiliar para retornar FwTemporaryTable
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 12/02/2021
	@version 12.1.33
/*/
Static Function xCriaTRB(aFields,aIndex,oTrb,cTableName,nTipo)
	local aArea     := getArea()
	local aTmpIndx  := {}
	local i         := 0
	local lArray    := .F.
	local nX        := 0
	local oAux      := Nil
	local y         := 0
	Default aFields := {}
	Default aIndex  := {}
	Default cAlias  := Iif(empty(cTableName),getNextAlias(),cTableName)
	Default nTipo   := 1
	Default oTrb    := Nil


	Do Case
	Case ( len(aFields) ==0 )
		MsgInfo("A Estrutura do campo field est� incorreta( os campos da estrutura para montagem do TRB devem ser obrigatoriamente enviados ). Por favor, revisar o mesmo para prosseguir com a opera��o.","Inconsist�ncia")
		Return .F.
	EndCase

	oAux := FWTemporaryTable():New(cAlias)
	oAux:SetFields( aFields )
	If nTipo == 1
		For y := 1 to len(aIndex)
			lArray := ValType(aIndex[y])=="A"
			If( lArray )
				lArray := ValType(aIndex[y,2])=="A"
				If( lArray )
					For i := 1 to len(aIndex[y,2])
						oAux:AddIndex(StrZero((y+i),7), { aIndex[y,2,i] } )
					Next i
				Else
					oAux:AddIndex(StrZero(y,7), { aIndex[y,2] } )
				EndIf
			Else
				oAux:AddIndex(StrZero(y,7), { aIndex[y,2] } )
			EndIf
		Next y
	Else
		For y := 1 to len(aIndex)
			aTmpIndx:= {}
			aTmpIndx:= Array(Len(aIndex[y,2]))
			For nX:= 1 to Len(aIndex[y,2])
				aTmpIndx[nX]:= aIndex[y,2,nX]
			Next nX
			If Len(aTmpIndx) > 0
				oAux:AddIndex(StrZero(y,7), aTmpIndx )
			EndIf
		Next y
	EndIf
	oAux:Create()
	oTrb := oAux
	cTableName := oTrb:GetAlias()

	RestArea(aArea)

Return( .T. )
/*/{Protheus.doc} fImport
	Fun��o respons�vel por fazer a importa��o dos dados
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fImport(aOriginal)
	Local aAuxAtu     := {}
	Local aGenero     := FWGetSX5( 'ZG' )
	Local aRacaid	  := FWGetSX5( 'ZH' )
	Local cArqLog     := ""
	Local cChavGenero := ""
	Local cChaveRaca  := ""
	Local cCodAux     := ""
	Local cConLog     := ""
	Local cDescGenero := ""
	Local cDescRaca   := ""
	Local cFilSra     := ""
	Local cLinAtu     := ""
	Local cMatSra     := ""
	Local cSequen     := StrZero(1, 10)
	Local lFalhou     := .F.
	Local nLinAtu     := 1
	Local nPosAux     := 1
	Local nX          := 0
	Local xConteud    := ""
	Private aDados    := {}
	Default aOriginal := {}

	If Select('SRA') <= 0
		dbSelectArea('SRA')
	EndIf
	SRA->( dbSetOrder( 1 ) ) //RA_FILIAL+RA_MAT

	ProcRegua(nTotalReg)

	//Percorrendo os registros
	While nLinAtu <= nTotalReg
		IncProc("Analisando linha "+cValToChar(nLinAtu)+" de "+cValToChar(nTotalReg)+"...")
		cArqLog := "log_"+cCmbTip+"_lin_"+cValToChar(nLinAtu)+"_"+dToS(dDataBase)+"_"+StrTran(Time(), ":", "-")+".txt"
		cConLog := "Tipo:     "+cCmbTip+CRLF
		cConLog += "Usu�rio:  "+UsrRetName(RetCodUsr())+CRLF
		cConLog += "Ambiente: "+GetEnvServer()+CRLF
		cConLog += "Data:     "+dToC(dDataBase)+CRLF
		cConLog += "Hora:     "+Time()+CRLF
		cConLog += "----"+CRLF+CRLF

		//Pegando a linha atual e transformando em array
		cLinAtu := aOriginal[nLinAtu]
		aAuxAtu := Separa(cLinAtu, cGetCar)
		cCodAux := "" // Limpando o codigo auxiliar

		//Se tiver dados
		If !Empty(cLinAtu)
			//Se o tamanho for diferente, registra erro
			If Len(aAuxAtu) != Len(aHeadImp)
				cConLog += "O tamanho de campos da linha, difere do tamanho de campos do cabe�alho!"+CRLF
				cConLog += "Linha:     "+cValToChar(Len(aAuxAtu))+CRLF
				cConLog += "Cabe�alho: "+cValToChar(Len(aHeadImp))+CRLF

				//Gerando o arquivo
				MemoWrite(cDirTmp+cArqLog, cConLog)

				//Gravando o registro
				RecLock(cAliasTmp, .T.)
				TMP_ARQ   := cArqLog
				TMP_LINHA := nLinAtu
				TMP_SEQ   := cSequen
				(cAliasTmp)->(MsUnlock())

				//Incrementa a sequencia
				cSequen := Soma1(cSequen)

				//Sen�o, carrega as informa��es no array
			Else
				aDados	:= {}
				lFalhou:= .F.

				//Iniciando a transa��o
				Begin Transaction
					//Percorre o cabe�alho
					For nPosAux := 1 To Len(aHeadImp)
						xConteud := aAuxAtu[nPosAux]

						//Se o tipo do campo for Num�rico
						If aHeadImp[nPosAux][2] == 'N'
							xConteud := Val(aAuxAtu[nPosAux])

							//Se o tipo for L�gico
						ElseIf aHeadImp[nPosAux][2] == 'L'
							xConteud := Iif(aAuxAtu[nPosAux] == '.T.', .T., .F.)

							//Se o tipo for Data
						ElseIf aHeadImp[nPosAux][2] == 'D'
							//Se tiver '/' na data, � padr�o DD/MM/YYYY
							If '/' $ aAuxAtu[nPosAux]
								xConteud := cToD(aAuxAtu[nPosAux])

								//Sen�o, � padr�o YYYYMMDD
							Else
								xConteud := sToD(aAuxAtu[nPosAux])
							EndIf
						EndIf

						//Se for o campo filial
						If 'RA_FILIAL' $ aHeadImp[nPosAux][1]
							cFilSra := aAuxAtu[nPosAux]
							cFilSra := PadR( cFilSra, TamSx3('RA_FILIAL')[1] )
						EndIf

						If 'RA_MAT' $ aHeadImp[nPosAux][1]
							cMatSra := aAuxAtu[nPosAux]
							cMatSra := PadR( cMatSra, TamSx3('RA_MAT')[1] )
						EndIf

						If 'RA_XGENERO' $ aHeadImp[nPosAux][1]
							cRA_XGENERO := Upper(aAuxAtu[nPosAux])
						EndIf

						If 'RA_XNAMESO' $ aHeadImp[nPosAux][1]
							cRA_XNAMESO := aAuxAtu[nPosAux]
						EndIf

						If 'RA_XUSASOC' $ aHeadImp[nPosAux][1]
							cRA_XUSASOC := Upper(aAuxAtu[nPosAux])
						EndIf

						If 'RA_XCODRAC' $ aHeadImp[nPosAux][1]
							cRA_XCODRAC := Upper(aAuxAtu[nPosAux])
						EndIf

						//Adicionando no vetor que ser� importado
						aAdd(aDados,{	aHeadImp[nPosAux][1],;			//Campo
						xConteud,;							//Conte�do
						Nil})								//Compatibilidade


					Next


				End Transaction

				If !SRA->(DbSeek( cFilSra + cMatSra))
					lFalhou := .T.

					cConLog += "N�o foi encontrado um registro na SRA para a Filial :" + cFilSra + ' e Matricula : ' + cMatSra
					cConLog += " retirar ou ajustar do arquivo"
					cConLog+= CRLF

				Else

					If !Empty(SRA->RA_XGENERO) .Or. !Empty(SRA->RA_XNAMESO) .Or. !Empty(SRA->RA_XUSASOC) .Or. !Empty(SRA->RA_XCODRAC)
						lFalhou := .T.

						cConLog += "J� existe um registro preenchido na SRA para a Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If ! ( cRA_XUSASOC $ 'S|N' )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o S ou N para o campo RA_XUSASOC Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If len(aGenero) > 0
						For nX := 1 to len(aGenero)
							cChavGenero += Alltrim(aGenero[nX][3]) + '|' 
							cDescGenero += Alltrim(aGenero[nX][3]) + '- ' + Alltrim(aGenero[nX][4]) + '|'
						Next
					EndIf

					If ! ( cRA_XGENERO $ cChavGenero )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o " + cDescGenero + " para o campo RA_XGENERO Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If cRA_XUSASOC == 'S' .And. ( Empty(cRA_XGENERO) .Or. Empty(cRA_XNAMESO) )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois como foi indicado o uso do nome social devem ser enviados os campos RA_XGENERO e RA_XNAMESO  preenchidos Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If len(aRacaid) > 0
						For nX := 1 to len(aRacaid)
							cChaveRaca += Alltrim(aRacaid[nX][3]) + '|' 
							cDescRaca += Alltrim(aRacaid[nX][3]) + '- ' + Alltrim(aRacaid[nX][4]) + '|'
						Next
					EndIf
					
					If ! ( cRA_XCODRAC $ cChaveRaca )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o " + cDescRaca + " para o campo RA_XGENERO Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf
					

				EndIf


				//Se houve falha na importa��o, grava na tabela tempor�ria
				If lFalhou
					//Gerando o arquivo
					MemoWrite(cDirTmp+cArqLog, cConLog)

					//Gravando o registro
					RecLock(cAliasTmp, .T.)
					TMP_ARQ   := cArqLog
					TMP_LINHA := nLinAtu
					TMP_SEQ   := cSequen
					(cAliasTmp)->(MsUnlock())

					//Incrementa a sequencia
					cSequen := Soma1(cSequen)
				EndIf
			EndIf
		EndIf

		nLinAtu++

	EndDo
Return
/*/{Protheus.doc} fOkImport
	Fun��o respons�vel por fazer a importa��o dos dados Validos
	@type  Function Static
	@author Cleiton Genuino da Silva
	@since 29/11/2023
	@version 12.1.33
/*/
Static Function fOkImport(aOriginal)
	Local aAuxAtu     := {}
	Local aGenero     := FWGetSX5( 'ZG' )
	Local aRacaid     := FWGetSX5( 'ZH' )
	Local cArqLog     := ""
	Local cChavGenero := ""
	Local cChaveRaca  := ""
	Local cCodAux     := ""
	Local cConLog     := ""
	Local cDescGenero := ""
	Local cDescRaca   := ""
	Local cFilSra     := ""
	Local cLinAtu     := ""
	Local cMatSra     := ""
	Local cSequen     := StrZero(1, 10)
	Local lFalhou     := .F.
	Local nLinAtu     := 1
	Local nPosAux     := 1
	Local nX          := 0
	Local xConteud    := ""
	Private aDados    := {}
	Default aOriginal := {}

	If Select('SRA') <= 0
		dbSelectArea('SRA')
	EndIf
	SRA->( dbSetOrder( 1 ) ) //RA_FILIAL+RA_MAT

	ProcRegua(nTotalReg)

	//Percorrendo os registros
	While nLinAtu <= nTotalReg
		IncProc("Analisando linha "+cValToChar(nLinAtu)+" de "+cValToChar(nTotalReg)+"...")
		cArqLog := "log_"+cCmbTip+"_lin_"+cValToChar(nLinAtu)+"_"+dToS(dDataBase)+"_"+StrTran(Time(), ":", "-")+".txt"
		cConLog := "Tipo:     "+cCmbTip+CRLF
		cConLog += "Usu�rio:  "+UsrRetName(RetCodUsr())+CRLF
		cConLog += "Ambiente: "+GetEnvServer()+CRLF
		cConLog += "Data:     "+dToC(dDataBase)+CRLF
		cConLog += "Hora:     "+Time()+CRLF
		cConLog += "----"+CRLF+CRLF

		//Pegando a linha atual e transformando em array
		cLinAtu := aOriginal[nLinAtu]
		aAuxAtu := Separa(cLinAtu, cGetCar)
		cCodAux := "" // Limpando o codigo auxiliar

		//Se tiver dados
		If !Empty(cLinAtu)
			//Se o tamanho for diferente, registra erro
			If Len(aAuxAtu) != Len(aHeadImp)
				cConLog += "O tamanho de campos da linha, difere do tamanho de campos do cabe�alho!"+CRLF
				cConLog += "Linha:     "+cValToChar(Len(aAuxAtu))+CRLF
				cConLog += "Cabe�alho: "+cValToChar(Len(aHeadImp))+CRLF

				//Gerando o arquivo
				MemoWrite(cDirTmp+cArqLog, cConLog)

				//Gravando o registro
				RecLock(cAliasTmp, .T.)
				TMP_ARQ   := cArqLog
				TMP_LINHA := nLinAtu
				TMP_SEQ   := cSequen
				(cAliasTmp)->(MsUnlock())

				//Incrementa a sequencia
				cSequen := Soma1(cSequen)

				//Sen�o, carrega as informa��es no array
			Else
				aDados	:= {}
				lFalhou:= .F.

				//Iniciando a transa��o
				Begin Transaction
					//Percorre o cabe�alho
					For nPosAux := 1 To Len(aHeadImp)
						xConteud := aAuxAtu[nPosAux]

						//Se o tipo do campo for Num�rico
						If aHeadImp[nPosAux][2] == 'N'
							xConteud := Val(aAuxAtu[nPosAux])

							//Se o tipo for L�gico
						ElseIf aHeadImp[nPosAux][2] == 'L'
							xConteud := Iif(aAuxAtu[nPosAux] == '.T.', .T., .F.)

							//Se o tipo for Data
						ElseIf aHeadImp[nPosAux][2] == 'D'
							//Se tiver '/' na data, � padr�o DD/MM/YYYY
							If '/' $ aAuxAtu[nPosAux]
								xConteud := cToD(aAuxAtu[nPosAux])

								//Sen�o, � padr�o YYYYMMDD
							Else
								xConteud := sToD(aAuxAtu[nPosAux])
							EndIf
						EndIf

						//Se for o campo filial
						If 'RA_FILIAL' $ aHeadImp[nPosAux][1]
							cFilSra := aAuxAtu[nPosAux]
							cFilSra := PadR( cFilSra, TamSx3('RA_FILIAL')[1] )
						EndIf

						If 'RA_MAT' $ aHeadImp[nPosAux][1]
							cMatSra := aAuxAtu[nPosAux]
							cMatSra := PadR( cMatSra, TamSx3('RA_MAT')[1] )
						EndIf

						If 'RA_XGENERO' $ aHeadImp[nPosAux][1]
							cRA_XGENERO := Upper(aAuxAtu[nPosAux])
						EndIf

						If 'RA_XNAMESO' $ aHeadImp[nPosAux][1]
							cRA_XNAMESO := aAuxAtu[nPosAux]
						EndIf

						If 'RA_XUSASOC' $ aHeadImp[nPosAux][1]
							cRA_XUSASOC := Upper(aAuxAtu[nPosAux])
						EndIf

						If 'RA_XCODRAC' $ aHeadImp[nPosAux][1]
							cRA_XCODRAC := Upper(aAuxAtu[nPosAux])
						EndIf

						//Adicionando no vetor que ser� importado
						aAdd(aDados,{	aHeadImp[nPosAux][1],;			//Campo
						xConteud,;							//Conte�do
						Nil})								//Compatibilidade


					Next


				End Transaction

				If !SRA->(DbSeek( cFilSra + cMatSra))
					lFalhou := .T.

					cConLog += "N�o foi encontrado um registro na SRA para a Filial :" + cFilSra + ' e Matricula : ' + cMatSra
					cConLog += " retirar ou ajustar do arquivo"
					cConLog+= CRLF

				Else

					If !Empty(SRA->RA_XGENERO) .Or. !Empty(SRA->RA_XNAMESO) .Or. !Empty(SRA->RA_XUSASOC)
						lFalhou := .T.

						cConLog += "J� existe um registro preenchido na SRA para a Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If len(aGenero) > 0
						For nX := 1 to len(aGenero)
							cChavGenero += Alltrim(aGenero[nX][3]) + '|' 
							cDescGenero += Alltrim(aGenero[nX][3]) + '- ' + Alltrim(aGenero[nX][4]) + '|'
						Next
					EndIf

					If ! ( cRA_XGENERO $ cChavGenero )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o " + cDescGenero + " para o campo RA_XGENERO Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If ! ( cRA_XUSASOC $ 'S|N' )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o S ou N para o campo RA_XUSASOC Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf


					If cRA_XUSASOC == 'S' .And. ( Empty(cRA_XGENERO) .Or. Empty(cRA_XNAMESO) )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois como foi indicado o uso do nome social devem ser enviados os campos RA_XGENERO e RA_XNAMESO  preenchidos Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf

					If len(aRacaid) > 0
						For nX := 1 to len(aRacaid)
							cChaveRaca += Alltrim(aRacaid[nX][3]) + '|' 
							cDescraca += Alltrim(aRacaid[nX][3]) + '- ' + Alltrim(aRacaid[nX][4]) + '|'
						Next
					EndIf
					
					If ! ( cRA_XCODRAC $ cChaveRaca )
						lFalhou := .T.
						cConLog += "Ajuste o registro pois os valores aceitos s�o " + cDescRaca + " para o campo RA_XGENERO Filial :" + cFilSra + ' e Matricula : ' + cMatSra
						cConLog += " retirar ou ajustar do arquivo"
						cConLog+= CRLF
					EndIf
					

				EndIf


				//Se houve falha na importa��o, grava na tabela tempor�ria
				If lFalhou
					//Gerando o arquivo
					MemoWrite(cDirTmp+cArqLog, cConLog)

					//Gravando o registro
					RecLock(cAliasTmp, .T.)
					TMP_ARQ   := cArqLog
					TMP_LINHA := nLinAtu
					TMP_SEQ   := cSequen
					(cAliasTmp)->(MsUnlock())

					//Incrementa a sequencia
					cSequen := Soma1(cSequen)
				Else

					If SRA->(DbSeek( cFilSra + cMatSra))

						If Reclock('SRA',.F.)
							SRA->RA_XUSASOC := cRA_XUSASOC
							SRA->RA_XNAMESO := cRA_XNAMESO
							SRA->RA_XGENERO := Strzero(Val(cRA_XGENERO),2)
							SRA->RA_XCODRAC := Strzero(Val(cRA_XCODRAC),2)
							SRA->(MsUnlock())
						EndIf
					EndIf

				EndIf
			EndIf
		EndIf

		nLinAtu++

	EndDo
Return
