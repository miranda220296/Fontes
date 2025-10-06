#INCLUDE 'TOTVS.CH'
/*/{Protheus.doc} FSPE0021
	
    MTA110MNU - Adicona o bot�o de destravar Solicita��o na rotina de - Solicita��o de Compra MATA110.PRX

	@type Function - User function
	@author Cleiton Genuino
	@since 25/07/2023
	@version 1.0
/*/
User Function FSPE0021()

	aadd(aRotina,{'Destravar Solicita��o','U_ScUnlock',0, 4, 0, NIL})

Return aRotina
/*/{Protheus.doc} ScUnlock
	
    Rotina que destrava a SC ap�s falha de medi��o ou quebra de Scheduler durante medi��o.

	@type Function - User function
	@author Cleiton Genuino
	@since 16/06/2023
	@version 1.0
    @return logical, Se executado com sucesso retorna verdadiero caso contrario falso

/*/
User Function ScUnlock()
	Local aArea  := fwGetArea() as array
	Local cQuery := ''        as character
	Local lok    := .T.       as logical
	Local nCount := 0         as numeric

	If select('SC1') <= 0
		dbSelectArea("SC1")
	Endif

	If SC1->(!EOF())

		cQuery := "SELECT COUNT(R_E_C_N_O_) NREC FROM " + RetSqlName("SC1") + " WHERE C1_FILIAL='" + SC1->C1_FILIAL + "' AND C1_NUM='" + SC1->C1_NUM + "' AND C1_XNUMMED IN('XXXXXX','ZZZZZZ') AND D_E_L_E_T_ = ' '"
		nCount := MpSysExecScalar(cQuery,"NREC")

		If nCount > 0
			If MsgYesNo("Confirma destravar a solicitac�o " + SC1->C1_NUM + " ?", "Aten��o")
				If U_ValSenior(SC1->C1_FILIAL, SC1->C1_NUM, SC1->C1_GRUPCOM )
					RptStatus({|| U_fCleanSc( SC1->C1_FILIAL, SC1->C1_NUM , nCount )}, "Aguarde...", "Executando rotina...")
					lok := .F.
                Else
                    MsgAlert("A solicita��o "+ SC1->C1_NUM + " est� bloqueada por: " + SC1->C1_XUSR + "-"+ UsrRetName(SC1->C1_XUSR)+  " e voc� n�o possui privil�gio de desbloqueio !", "Atencao!")
				EndIf
			EndIf
		Else
			MsgAlert("A solicita��o selecionada n�o possui item bloqueado !", "Atencao!")
		EndIf
	Else
		MsgAlert("Voc� precisa estar posicionado para usar essa fun��o utilize a fCleanSc passando o parametros corretamente !", "Atencao!")
	ENDIF

	fwrestarea	(aArea)

Return lok
/*/{Protheus.doc} fCleanSc
	
    Fun��o generica para limpeza da SC

	@type Function - User function
	@author Cleiton Genuino
	@since 16/06/2023
	@version 1.0
    @return logical, Se executado com sucesso retorna verdadiero caso contrario falso

/*/
User Function fCleanSc(cFilSc,cNumSc,nCount)
	Local aArea    := fwGetArea()      as array
	Local cAlias   := GetNextAlias() as character
	Local lExist   := .F.            as logical
	Default cFilSc := ''
	Default cNumSc := ''
	Default nCount := 0

	If select('SC1') <= 0
		dbSelectArea("SC1")
	Endif
	SC1->(dbSetOrder(1)) // C1_FILIAL + C1_NUM + C1_ITEM + C1_ITEMGRD

	lExist := SC1->( dbseek(  cFilSc + cNumSc  ))

	If lExist

		BeginSql alias cAlias
        SELECT
            C1_FILIAL,
            C1_NUM,
            C1_ITEM,
            C1_ITEMGRD
        FROM
            %Table:SC1% SC1
        WHERE
            C1_FILIAL = %exp:cFilSc%
            AND C1_NUM = %exp:cNumSc%
            AND SC1.%NotDel% 
		EndSql

		SetRegua(nCount)

		While (cAlias)->(!EOF())

			cBusca := PadR((cAlias)->C1_FILIAL	, TamSX3("C1_FILIAL")[1])
			cBusca += PadR((cAlias)->C1_NUM		, TamSX3("C1_NUM")[1])
			cBusca += PadR((cAlias)->C1_ITEM	, TamSX3("C1_ITEM")[1])
			cBusca += PadR((cAlias)->C1_ITEMGRD	, TamSX3("C1_ITEMGRD")[1])

			If SC1->( dbseek(  cBusca  )) .And. RecLock('SC1',.F.)
				SC1->C1_XNUMMED := ''
				SC1->C1_XUSR    := ''
				SC1->C1_XDTMED	:= stod("")
				SC1->C1_XHRMED	:= ''
				SC1->(MsUnlock())
			EndIf

			IncRegua()

			(cAlias)->(dbskip())

		Enddo

	else
		MsgAlert("A solicita��o selecionada n�o foi encontrada!", "Atencao!")
	EndIf

	(cAlias)->(DbCloseArea())

	fwrestarea	(aArea)

Return lExist
/*/{Protheus.doc} ValSenior
	
    Fun��o para validar se o usu�rio pode destrava a SC ou se participa do grupo de Senior

	@type Function - User function
	@author Cleiton Genuino
	@since 16/06/2023
	@version 1.0
	@param cFilSc	, Character, C�digo da filial corrente
	@param cNumSc	, Character, N�mero da Solicita��o de Compra posicionada
	@param cGrupoSc	, Character, N�mero da Grupo da Solicita��o de Compra posicionada
    @return logical, Se executado com sucesso retorna verdadiero caso contrario falso

/*/
User Function ValSenior(cFilSc,cNumSc,cGrupoSc)
	Local aArea      := fwGetArea()                                as array
	Local cAlias     := GetNextAlias()                           as character
	Local cGrpSenior := SUPERGETMV( 'RD_SENIOR' ,.F., '000000' ) as character
	Local cNameUsr   := RetCodUsr()                              as character
	Local lOk        := .F.                                      as logical
	Private aGrupo   := UsrRetGrp(RetCodUsr())                   as array
	Default cFilSc   := cFilAnt
	Default cGrupoSc := ''
	Default cNumSc   := ''

	cGrpSenior+='|000188|000362|' // Default Grupos Senior

	cFilAnt := cFilSc

	If select('SC1') <= 0
		dbSelectArea("SC1")
	Endif
	SC1->(dbSetOrder(1)) // C1_FILIAL + C1_NUM + C1_ITEM + C1_ITEMGRD

	BeginSql alias cAlias
		SELECT
			C1_XUSR
		FROM
			%Table:SC1% SC1
		WHERE
			C1_FILIAL = %exp:cFilSc%
			AND C1_NUM = %exp:cNumSc%
			AND SC1.%NotDel% 
	EndSql

	While (cAlias)->(!EOF())
		If Alltrim(cNameUsr) == Alltrim((cAlias)->C1_XUSR)
			lOk := .T.
			EXIT
		EndIf
		(cAlias)->(dbskip())
	Enddo

	If ! lOk .And. ! Empty(cGrupoSc) // Se grupo estiver em branco somente o usu�rio pode destravar o processo
		If VALTYPE( aGrupo ) == 'A'
			If Ascan(aGrupo,{|x| x $ cGrpSenior}) > 0  // � senior ?
				lOk := VldGrComp(cNameUsr,cGrupoSc) // Se o senior estiver no mesmo grupo do usu�rio que travou ele pode destravar
			EndIf
		EndIf
	EndIf

	fwrestarea	(aArea)
	(cAlias)->(DbCloseArea())

Return lOk
