// #########################################################################################
// Projeto: Rede D'Or
// Modulo : Financeiro
// Fonte  : F241IMP
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------
// 16/06/24 | Rafael Yera Barchi| Ponto de Entrada para gravação complementar após de 
//          |                   | impostos na rotina Bordero de Impostos
// ---------+-------------------+-----------------------------------------------------------

#INCLUDE    "PROTHEUS.CH"


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} F241IMP
//Ponto de Entrada para gravação complementar de impostos na rotina Bordero de Impostos
@author Rafael Yera Barchi
@since 16/06/2024
@version 1.00
@type function

/*/
//------------------------------------------------------------------------------------------
User Function F241IMP()

	Local aAreaSE2      := SE2->(GetArea())
	Local cSQL          := ""
	Local cEOL          := Chr(13) + Chr(10)
	Local cAliasTRB     := GetNextAlias()
	Local nCount        := 0
	Local nReg          := 0
	Local nVlPCC        := 0
	Local nRecE2        := SE2->(RECNO())

	nVlPCC := fAtuPCC()

	SE2->(DbGoto(nRecE2))

	Reclock("SE2",.F.)
	    SE2->E2_SALDO := SE2->E2_SALDO - nVlPCC
	SE2->(MSUnLock())

	cSQL := " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, E2_VALOR, E2_PIS, E2_COFINS, E2_CSLL, E2_FATPREF, E2_FATURA, E2_FATFOR, E2_FATLOJ, E2_TIPOFAT, E2_BASEPIS, E2_BASECOF, E2_BASECSL, SE2.R_E_C_N_O_ NUMREG " + cEOL
	CSQL += "   FROM " + RetSQLName("SE2") + " SE2 " + cEOL
	cSQL += "  WHERE E2_FILIAL = '" + FWxFilial("SE2") + "' " + cEOL
	cSQL += "    AND E2_FATPREF = '" + SE2->E2_PREFIXO + "'" + cEOL
	cSQL += "    AND E2_FATURA = '" + SE2->E2_NUM + "'" + cEOL
	cSQL += "    AND E2_FATFOR = '" + SE2->E2_FORNECE + "'" + cEOL
	cSQL += "    AND E2_FATLOJ = '" + SE2->E2_LOJA + "'" + cEOL
	cSQL += "    AND E2_TIPOFAT = '" + SE2->E2_TIPO + "'" + cEOL
	cSQL += "    AND E2_FLAGFAT = 'S'" + cEOL
	cSQL += "    AND E2_XMNKLOT <> '" + Space(TamSX3("E2_XMNKLOT")[1]) + "'" + cEOL
	cSQL += "    AND SE2.D_E_L_E_T_ = ' ' " + cEOL

	If Select(cAliasTRB) > 0
		(cAliasTRB)->(DBCloseArea())
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry( , , cSQL), (cAliasTRB), .F., .T.)

	Count To nCount

	(cAliasTRB)->(DBSelectArea(cAliasTRB))
	(cAliasTRB)->(DBGoTop())
	While !(cAliasTRB)->(EOF())

		If nReg == 0
			nReg := (cAliasTRB)->NUMREG
		EndIf

		// Variáveis de escopo Private do programa padrão F241IMP
		nPis    := (cAliasTRB)->E2_PIS
		nCofins := (cAliasTRB)->E2_COFINS
		nCsll   := (cAliasTRB)->E2_CSLL

		(cAliasTRB)->(DBSkip())

	EndDo

	If Select(cAliasTRB) > 0
		(cAliasTRB)->(DBCloseArea())
	EndIf

	RestArea(aAreaSE2)

	// Posiciono no título de origem para que a geração seja pelo título de origem e não pela fatura
	If nReg > 0
		SE2->(DBSelectArea("SE2"))
		SE2->(DBSetOrder(1))
		SE2->(DBGoTo(nReg))
	EndIf

Return


Static Function fAtuPCC()

	Local aArea 		:= GetArea()
	Local aAreSE2      	:= SE2->(GetArea())
	Local nIdxSE2 		:= SE2->(IndexOrd())
	Local nRegSE2 		:= SE2->(Recno())
	Local aAreSE5      	:= SE5->(GetArea())
	Local nIdxSE5 		:= SE5->(IndexOrd())
	Local nRegSE5 		:= SE5->(Recno())
	Local nTotal        := 0
	Local cSQL          := ""
	Local cEOL          := Chr(13) + Chr(10)
	Local cAliasTRB     := GetNextAlias()
	Local nCount        := 0
	Local lMonkey 		:= .F.
	Local cMKPref    	:= SuperGetMV("MK_PREFIXO", , "NEG")
	Local cFornPCC 		:= SuperGetMV("MK_FORNPCC", , "UNIAO ")
	Local cLojaPCC 		:= SuperGetMV("MK_LOJAPCC", , "00")
	Local cLogDir		:= SuperGetMV("MK_LOGDIR", , "\log\")
	Local cLogArq		:= "F240CAN"

	cSQL := " SELECT SE2.R_E_C_N_O_ NUMREG " + cEOL
	CSQL += "   FROM " + RetSQLName("SE2") + " SE2 " + cEOL
	cSQL += "  WHERE E2_FILIAL = '" + FWxFilial("SE2") + "' " + cEOL
//  cSQL += "    AND E2_PREFIXO = '" + SEA->EA_PREFIXO + "' " + cEOL
	cSQL += "    AND E2_PREFIXO = '" + cMKPref + "' " + cEOL
	cSQL += "    AND E2_NUM = '" + SEA->EA_NUM + "' " + cEOL
	cSQL += "    AND E2_FORNECE = '" + cFornPCC + "' " + cEOL
	cSQL += "    AND E2_LOJA = '" + cLojaPCC + "' " + cEOL
	cSQL += "    AND E2_TIPO = 'TX ' " + cEOL
	cSQL += "    AND SE2.D_E_L_E_T_ = ' ' " + cEOL

	MemoWrite(cLogDir + cLogArq + ".sql", cSQL)

	If Select(cAliasTRB) > 0
		(cAliasTRB)->(DBCloseArea())
	EndIf
	DBUseArea(.T., "TOPCONN", TCGenQry( , , cSQL), (cAliasTRB), .F., .T.)

	Count To nCount

	(cAliasTRB)->(DBSelectArea(cAliasTRB))
	(cAliasTRB)->(DBGoTop())
	While !(cAliasTRB)->(EOF())

		lMonkey := .T.

		SE2->(DBSelectArea("SE2"))
		SE2->(DBSetOrder(1))
		SE2->(DBGoTo((cAliasTRB)->NUMREG))

		nTotal := nTotal + SE2->E2_SALDO

		(cAliasTRB)->(DBSkip())

	EndDo

	If Select(cAliasTRB) > 0
		(cAliasTRB)->(DBCloseArea())
	EndIf

	RestArea(aAreSE2)
	RestArea(aAreSE5)

	SE2->(DBSelectArea("SE2"))
	SE2->(DBSetOrder(nIdxSE2))
	SE2->(DBGoTo(nRegSE2))

	SE5->(DBSelectArea("SE5"))
	SE5->(DBSetOrder(nIdxSE5))
	SE5->(DBGoTo(nRegSE5))

	RestArea(aArea)

Return nTotal
