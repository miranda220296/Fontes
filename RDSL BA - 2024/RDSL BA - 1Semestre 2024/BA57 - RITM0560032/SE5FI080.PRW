#Include 'Protheus.ch'

User Function SE5FI080()

	Local cCamposE5 := PARAMIXB[1]
	Local cNome := UsrFullName(__cUserId)
	If Empty(cNome)
		cNome := "RPC"
	EndIf


		cCamposE5 += ",{"

		cCamposE5 += " 'E5_XLOGMOV',  '" + cNome+"'"

		cCamposE5 += "} "

		cCamposE5 += ",{"

		cCamposE5 += " 'E5_XHORMOV',  '" + Time()+"'"

		cCamposE5 += "} "

		cCamposE5 += ",{"

		cCamposE5 += " 'E5_XDATMOV', ddatabase" 

		cCamposE5 += "} "


Return cCamposE5
