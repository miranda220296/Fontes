#Include 'Protheus.ch'
#INCLUDE 'RWMAKE.CH'
#INCLUDE "TopConn.ch"

/*/{Protheus.doc} FCADZDR
Fonte responsável pelo cadastro do DE PARA P12SxP12FULL
@type function
@author Lucas Miranda de Aguiar
@since 08/02/2025
@version 1.0
@return NIL
/*/ 


User Function FCADZDR()

	Local aRotAdic := {{"Carga CSV","U_xfCargZDR",0,3}}
	Local bOK  := {||, fVeriDup()}
	Local aButtons :=  {}

	AxCadastro("ZDR", "DE PARA P12SxP12F",,, aRotAdic, , bOK, , , , , aButtons, , )

Return(.T.)


Static Function fVeriDup()
	Local aArea := GetArea()
	Local lRet := .T.
	Local cQuery := ""
	Local cAliasZDR := GetNextAlias()


	If INCLUI
		cQuery += "SELECT 'CDP12S' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDSIMP = '"+AllTrim(M->ZDR_CDSIMP)+"' AND ZDR_TIPODR = '"+AllTrim(M->ZDR_TIPODR)+" ' AND ZDR_FILDR = '"+M->ZDR_FILDR+"' "
		cQuery += " UNION ALL "
		cQuery += "SELECT 'CDP12F' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDFULL = '"+AllTrim(M->ZDR_CDFULL)+"' AND ZDR_TIPODR = '"+AllTrim(M->ZDR_TIPODR)+" ' AND ZDR_FILDR = '"+M->ZDR_FILDR+"' "

		TcQuery cQuery Alias ( cAliasZDR) New

		IF (cAliasZDR)->(!EOF())

			If ( cAliasZDR)->RESULT == "CDP12S"
				lRet := .F.
				Help(NIL, NIL, "Cadastro de DEPARA P12SxP12FULL", NIL, "Ja existe um registro com esse código P12Simplificado na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro."})
			ElseIf ( cAliasZDR)->RESULT == "CDP12F"
				lRet := .F.
				Help(NIL, NIL, "Cadastro de DEPARA P12SxP12FULL", NIL, "Ja existe um registro com esse código P12FULL na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro."})
			EndIf
		EndIf
	ElseIf ALTERA
		cQuery += "SELECT 'CDP12S' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDSIMP = '"+AllTrim(M->ZDR_CDSIMP)+"' AND R_E_C_N_O_ <> '"+AllTrim(cValToChar(ZDR->(RECNO())))+"' AND ZDR_TIPODR = '"+AllTrim(M->ZDR_TIPODR)+" ' AND ZDR_FILDR = '"+M->ZDR_FILDR+"' "
		cQuery += " UNION ALL "
		cQuery += "SELECT 'CDP12F' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDFULL = '"+AllTrim(M->ZDR_CDFULL)+"' AND R_E_C_N_O_ <> '"+AllTrim(cValToChar(ZDR->(RECNO())))+"' AND ZDR_TIPODR = '"+AllTrim(M->ZDR_TIPODR)+" ' AND ZDR_FILDR = '"+M->ZDR_FILDR+"' "

		TcQuery cQuery Alias ( cAliasZDR) New

		IF (cAliasZDR)->(!EOF())

			If ( cAliasZDR)->RESULT == "CDP12S"
				lRet := .F.
				Help(NIL, NIL, "Cadastro de DEPARA P12SxP12FULL", NIL, "Ja existe um registro com esse código P12Simplificado na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro."})
			ElseIf ( cAliasZDR)->RESULT == "CDP12F"
				lRet := .F.
				Help(NIL, NIL, "Cadastro de DEPARA P12SxP12FULL", NIL, "Ja existe um registro com esse código P12FULL na tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro."})
			EndIf
		EndIf
	EndIf



	RestArea(aArea)
Return lRet




User Function xfCargZDR()
	Local aArea     := GetArea()
	Private cArqOri := ""

	//Mostra o Prompt para selecionar arquivos
	cArqOri := tFileDialog( "CSV files (*.csv) ", 'Seleção de Arquivos', , , .F., )

	//Se tiver o arquivo de origem
	If ! Empty(cArqOri)

		//Somente se existir o arquivo e for com a extensão CSV
		If File(cArqOri) .And. Upper(SubStr(cArqOri, RAt('.', cArqOri) + 1, 3)) == 'CSV'
			Processa({|| fCargZDR() }, "Importando...")
		Else
			MsgStop("Arquivo e/ou extensão inválida!", "Atenção")
		EndIf
	EndIf

	RestArea(aArea)
Return


Static Function fCargZDR()

	Local aArea      := GetArea()
	Local cArqLog    := "zImpCSV_" + dToS(Date()) + "_" + StrTran(Time(), ':', '-') + ".txt"
	Local nTotLinhas := 0
	Local cLinAtu    := ""
	Local nLinhaAtu  := 0
	Local aLinha     := {}
	Local oArquivo
	Local aLinhas
	Local cTipoDR   := ""
	Local cCodFull   := ""
	Local cFilZDR    := ""
	Local cCodSimp  := ""
	Local lContinua := .T.

	Local cQuery := ""
	Local cAliasZDR := GetNextAlias()
	Private cDirLog    := GetTempPath() + "x_importacao\"
	Private cLog       := ""


	//Se a pasta de log não existir, cria ela
	If ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIf

	//Definindo o arquivo a ser lido
	oArquivo := FWFileReader():New(cArqOri)

	//Se o arquivo pode ser aberto
	If (oArquivo:Open())

		//Se não for fim do arquivo
		If ! (oArquivo:EoF())

			//Definindo o tamanho da régua
			aLinhas := oArquivo:GetAllLines()
			nTotLinhas := Len(aLinhas)
			ProcRegua(nTotLinhas)

			//Método GoTop não funciona (dependendo da versão da LIB), deve fechar e abrir novamente o arquivo
			oArquivo:Close()
			oArquivo := FWFileReader():New(cArqOri)
			oArquivo:Open()

			//Enquanto tiver linhas
			While (oArquivo:HasLine())

				//Incrementa na tela a mensagem
				nLinhaAtu++
				IncProc("Analisando linha " + cValToChar(nLinhaAtu) + " de " + cValToChar(nTotLinhas) + "...")

				//Pegando a linha atual e transformando em array
				cLinAtu := oArquivo:GetLine()
				aLinha  := StrTokArr(cLinAtu, ";")

				//Se não for o cabeçalho (encontrar o texto "Código" na linha atual)
				If nLinhaAtu == 1
					If ! "ZDR_FILDR;ZDR_CDSIMP;ZDR_CDFULL;ZDR_TIPODR" == AllTrim(cLinAtu)
						MsgStop("Favor verificar o layout do arquivo, a primeira linha deve conter o cabeçalho de acordo com o padrão ZDR_FILDR;ZDR_CDSIMP;ZDR_CDFULL;ZDR_TIPODR ","Atenção!!")
						Return
					EndIf
				EndIf

				If nLinhaAtu == 1
					If  "ZDR_FILIAL" $ AllTrim(cLinAtu)
						MsgStop("Favor verificar o layout do arquivo, não é permitido carregar o campo de filial padrão, favor utilizar o campo ZDR_FILDR.","Atenção!!")
						Return
					EndIf
				EndIf

				If nLinhaAtu <> 1
					lContinua := .T.
					If (Len(aLinha) <> 4)
						cLog += "----------------------------------------------------------------------------"
						cLog += CRLF
						cLog += "Linha " + cValToChar(nLinhaAtu)
						cLog += CRLF
						cLog += "Resultado: Favor verificar estrutura de campos do arquivo! (Quantidade de colunas inferior ao cabeçalho)"
						cLog += CRLF
						cLog += "----------------------------------------------------------------------------"
						lContinua := .F.
					EndIf

					If lContinua
						//Zera as variaveis
						cFilZDR   := AllTrim(aLinha[1])
						cCodSimp  := AllTrim(aLinha[2])
						cCodFull  := AllTrim(aLinha[3])
						cTipoDR   := AllTrim(aLinha[4])
						cQuery    := ""
						lContinua := .T.

						If (Empty(cCodSimp) .Or. Empty(cCodFull) .Or. Empty(cTipoDR))
							cLog += "----------------------------------------------------------------------------"
							cLog += CRLF
							cLog += "Linha " + cValToChar(nLinhaAtu) + ", Filial DR [" + cFilZDR + "] "  + ", CodigoP12S [" + cCodSimp + "] " + ", CodigoP12FULL [" + cCodFull + "] " + ", TipoDePara [" + cTipoDR + "] "
							cLog += CRLF
							cLog += "Resultado: Um dos campos obrigatórios está em branco. Favor verificar!."
							cLog += CRLF
							cLog += "----------------------------------------------------------------------------"
							lContinua := .F.
						EndIf
					EndIf

					If lContinua
						cQuery += "SELECT 'CDP12S' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDSIMP = '"+cCodSimp+"' AND ZDR_TIPODR = '"+cTipoDR+" ' AND ZDR_FILDR = '"+cFilZDR+"'"
						cQuery += " UNION ALL "
						cQuery += "SELECT 'CDP12F' AS RESULT FROM " + RetSQLName("ZDR") + " WHERE D_E_L_E_T_ = ' ' AND ZDR_CDFULL = '"+cCodFull+"' AND ZDR_TIPODR = '"+cTipoDR+" ' AND ZDR_FILDR = '"+cFilZDR+"'"

						TcQuery cQuery Alias ( cAliasZDR) New

						IF (cAliasZDR)->(!EOF())
							cLog += "----------------------------------------------------------------------------"
							cLog += CRLF
							cLog += "Linha " + cValToChar(nLinhaAtu) + ", Filial DR [" + cFilZDR + "] " + ", CodigoP12S [" + cCodSimp + "] " + ", CodigoP12FULL [" + cCodFull + "] " + ", TipoDePara [" + cTipoDR + "] "
							cLog += CRLF

							If ( cAliasZDR)->RESULT == "CDP12S"
								cLog += "Resultado: Ja existe um registro com esse código P12Simplificado na tabela."
							ElseIf ( cAliasZDR)->RESULT == "CDP12F"
								cLog += "Resultado: Ja existe um registro com esse código P12FULL na tabela."
							EndIf
							cLog += CRLF
							cLog += "----------------------------------------------------------------------------"
						Else
							cLog += "----------------------------------------------------------------------------"
							cLog += CRLF
							cLog += "Linha " + cValToChar(nLinhaAtu) + ", Filial DR [" + cFilZDR + "] " + ", CodigoP12S [" + cCodSimp + "] " + ", CodigoP12FULL [" + cCodFull + "] " + ", TipoDePara [" + cTipoDR + "] "
							cLog += CRLF
							Reclock("ZDR",.T.)
							ZDR->ZDR_FILDR := cFilZDR
							ZDR->ZDR_CDFULL := cCodFull
							ZDR->ZDR_CDSIMP := cCodSimp
							ZDR->ZDR_TIPODR := cTipoDR
							ZDR->(MsUnlock())

							cLog += "Resultado: Registro criado com sucesso! RECNO " + cValtoChar(ZDR->(RECNO()))
							cLog += CRLF
							cLog += "----------------------------------------------------------------------------"
						EndIf
						(cAliasZDR)->(DBCloseArea())
					EndIf
				EndIf
			EndDo

			//Se tiver log, mostra ele
			If ! Empty(cLog)
				cLog := "Processamento finalizado, abaixo as mensagens de log: " + CRLF + cLog
				MemoWrite(cDirLog + cArqLog, cLog)
				ShellExecute("OPEN", cArqLog, "", cDirLog, 1)
			EndIf

		Else
			MsgStop("Arquivo não tem conteúdo!", "Atenção")
		EndIf

		//Fecha o arquivo
		oArquivo:Close()
	Else
		MsgStop("Arquivo não pode ser aberto!", "Atenção")
	EndIf

	RestArea(aArea)
Return
