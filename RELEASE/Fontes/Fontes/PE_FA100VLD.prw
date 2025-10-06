#Include 'TOTVS.ch'

/*/{Protheus.doc} User Function FA100VLD
    Valida��o do cancelamento/exclus�o da movimenta��o banc�ria
    @type  Function
    @author Gianluca Moreira
    @since 31/05/2021
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6071360
    /*/
User Function FA100VLD()

    Local aAreaE5 := SE5->(GetArea())
	Local lExclui  :=  ParamIXB[1]
	Local lCancela := !ParamIXB[1]
	Local lRet     := .T.
	Local lGrpHblt  := .F.//Verifica tabela PX1 para a empresa/filial atual
	Local cCtbOn  := ""

	// ticket n� 12543360
	Local cUsrAlt := ""

	Conout("Entrou ponto de entrada FA100VLD " + Time())
	 lGrpHblt  := U_F2000132() //Verifica tabela PX1 para a empresa/filial atual
	 cCtbOn  := SuperGetMV('FS_C200040',, '')
	 cUsrAlt := USRFULLNAME(__cuserid)

	//Verifica se est� habilitada a integra��o neste grupo de empresas
	If lGrpHblt
		lRet := U_F2000410() //Valida se a movimenta��o veio do XRT
	EndIf

	//A doc. oficial da ExecAuto menciona o par�metro NCTBONLINE para controlar
	//se contabiliza online ou n�o. Ap�s an�lise da rotina padr�o, verificou-se
	//que o par�metro n�o � utilizado, e � necess�rio alterar o MV_PAR04
	//manualmente neste ponto de entrada
	If FWIsInCallStack('U_F2000401') .And. !Empty(cCtbOn) .And. Type('MV_PAR04') != 'U'
		MV_PAR04 := Val(cCtbOn)
	EndIf

	// ticket n� 12543360 -- FINA100
	If lExclui //.Or. lCancela
		RecLock("SE5", .F. )
		SE5->E5_XLOGMOV  := cUsrAlt
		SE5->E5_XHORMOV  := TIME()
		SE5->E5_XDATMOV  := Date()
		SE5->(MsUnlock())
	EndIf

RestArea(aAreaE5)
Conout("Saiu ponto de entrada FA100VLD " + Time())
Return lRet
