#Include "Protheus.CH"

User Function F240BORD()
 
		Local aArea 		:= GetArea()
    Local aAreSE2      	:= SE2->(GetArea())
	Local nIdxSE2 		:= SE2->(IndexOrd())
	Local nRegSE2 		:= SE2->(Recno())
	Local nTotal := 0	
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
		RecLock("SE2", .F.)
			nTotal := nTotal + SE2->E2_SALDO
		SE2->(MSUnLock())
		(cAliasTRB)->(DBSkip())

	EndDo

    If Select(cAliasTRB) > 0
		(cAliasTRB)->(DBCloseArea())
	EndIf

	SE2->(DBSelectArea("SE2"))
	SE2->(DBSetOrder(1))
	SE2->(DbSeek(SEA->(EA_FILIAL+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA)))

	RecLock("SE2",.F.)
		SE2->E2_SALDO := SE2->E2_SALDO - nTotal
	SE2->(MSUnLock())

    RestArea(aAreSE2)
	SE2->(DBSelectArea("SE2"))
	SE2->(DBSetOrder(nIdxSE2))
	SE2->(DBGoTo(nRegSE2))

	RestArea(aArea)

Return
