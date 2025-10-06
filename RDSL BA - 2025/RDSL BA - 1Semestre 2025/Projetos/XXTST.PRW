#Include "Protheus.ch"


User Function XXTST()


	Local aArea := GetArea()
	Local nRet := 0


	If !IsinCallStack("MATA103")
		nRet := FORMULA("054")-FORMULA("055")
	EndIf
	RestArea(aArea)
Return nRet
