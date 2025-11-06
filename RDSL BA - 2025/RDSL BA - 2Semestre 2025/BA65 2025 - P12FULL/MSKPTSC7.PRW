#Include "Protheus.ch"

User Function MSKPTSC7()


	Local cAlias    := PARAMIXB[2]

	If AllTrim(cAlias) == "SC7"
		If SC7->C7_CONAPRO == "L" .And. SC7->C7_XSOLPAG == "1" .And. !Empty(SC7->C7_ZIDONGY)
			SC7->C7_ZINTOGY := "1"
		EndIf
	EndIf

Return
