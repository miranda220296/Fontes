#include "protheus.CH"
#include "TOTVS.CH"
#INCLUDE 'FWMVCDEF.CH'

/*{Protheus.doc} F0702402
A rotina de manutenção de campos exclusivos por filial estará 
disponível em “Outras Ações” na rotina de Cadastro de Produto 
@author Alex Sandro
@since 08/02/2017
@type
@project MAN0000007423041_EF_024
*/
User Function F0702402()

	Local aGroups := UsrRetGrp(RetCodUsr())
	Local lBlqPer := .F.
	Local cBloqPer := SuperGetMv( "FS_BLOQPER" , .F. , "" )
	Local nLoop := 0

	AAdd( aRotina, { 'Tratamento por Filiais - Visualizar'	, 'VIEWDEF.F0702402', 0, 1 } )
	AAdd( aRotina, { 'Tratamento por Filiais - Alterar   '	, 'VIEWDEF.F0702402', 0, 4 } )

	FOR nLoop := 1 TO LEN(aGroups)
		IF aGroups[nLoop] $ cBloqPer
			lBlqPer := .T.
		EndIf
	Next

	IF FindFunction('U_F1207401') .AND. lBlqPer
		AAdd( aRotina, { 'Bloq/Desbloq. Permanente Produto   '	, 'U_F1207401()', 0, 4 } )
	Endif

Return

/*{Protheus.doc} ModelDef
@author Alex Sandro
@since 08/02/2017
@project MAN0000007423041_EF_024
ModeDef Reescrito - Thais Paiva 16676552
*/
Static Function ModelDef()
	Local oModel 		:= Nil
	Local oStPai 		:= FWFormStruct(1, 'SB1')
	Local oStFilho 		:= MDStFilho()//FWFormStruct(1, 'P17') Thais Paiva 16676552
	Local oStMatriz		:= MDStMatriz() //Thais Paiva 16676552
	Local aP17Rel		:= {}
	Local nCampo        := 0
	Local nQtdCampo     := 0
	Local aGatP30P31    := {}
	Local cFilFil		:= ""
	Local cFilMat		:= ""
	Local bPostMod	:= {|| .T. }
	Local bPreValid := {|| .T. }

	cFilMat	:= "(EXISTS (SELECT P30_CODFIL FROM "+RetSqlName("P30")+" WHERE P30_FILIAL = P17_FILIAL AND P30_CODFIL = P17_FTRATA AND P30_CORP = '1' AND D_E_L_E_T_ = ' ')) OR "
	cFilMat	+= "(EXISTS (SELECT P31_CODFIL FROM "+RetSqlName("P31")+" WHERE P31_FILIAL = P17_FILIAL AND P31_CODFIL = P17_FTRATA AND D_E_L_E_T_ = ' ' AND P31_CORP = '1'))"

	cFilFil := "(EXISTS (SELECT P31_CODFIL FROM "+RetSqlName("P31")+" WHERE P31_FILIAL = P17_FILIAL AND P31_CODFIL = P17_FTRATA AND D_E_L_E_T_ = ' ' AND P31_CORP <> '1')) OR "
	cFilFil += "(EXISTS (SELECT P30_CODFIL FROM "+RetSqlName("P30")+" WHERE P30_FILIAL = P17_FILIAL AND P30_CODFIL = P17_FTRATA AND P30_CORP <> '1' AND D_E_L_E_T_ = ' '))"

	/*/cFilMat :=   " EXISTS (SELECT CODFIL FROM ( "
	cFilMat +=   " SELECT DISTINCT P30_CODFIL AS CODFIL FROM " +RetSqlName("P30")+ " P30"
	cFilMat +=   " INNER JOIN " +RetSqlName("P17")+  " P17 ON P17.P17_FTRATA = P30.P30_CODFIL AND P17.D_E_L_E_T_ = ' '"
	cFilMat +=   " WHERE P30.D_E_L_E_T_ = ' ' AND P30.P30_CORP = '1'"
	cFilMat +=   " UNION ALL"
	cFilMat +=   " SELECT DISTINCT P31_CODFIL AS CODFIL FROM " +RetSqlName("P31")+  " P31 "
	cFilMat +=   " INNER JOIN " +RetSqlName("P17")+  " P17 ON P17.P17_FTRATA = P31.P31_CODFIL AND P17.D_E_L_E_T_ = ' '"
	cFilMat +=   " WHERE P31.D_E_L_E_T_ = ' ' AND P31.P31_CORP = '1'))"

	cFilFil :=   " EXISTS (SELECT CODFIL FROM ( "
	cFilFil +=   " SELECT DISTINCT P30_CODFIL AS CODFIL FROM " +RetSqlName("P30")+ " P30"
	cFilFil +=   " INNER JOIN " +RetSqlName("P17")+  " P17 ON P17.P17_FTRATA = P30.P30_CODFIL AND P17.D_E_L_E_T_ = ' '"
	cFilFil +=   " WHERE P30.D_E_L_E_T_ = ' ' AND P30.P30_CORP <> '1'"
	cFilFil +=   " UNION ALL"
	cFilFil +=   " SELECT DISTINCT P31_CODFIL AS CODFIL FROM " +RetSqlName("P31")+  " P31 "
	cFilFil +=   " INNER JOIN " +RetSqlName("P17")+  " P17 ON P17.P17_FTRATA = P31.P31_CODFIL AND P17.D_E_L_E_T_ = ' '"
	cFilFil +=   " WHERE P31.D_E_L_E_T_ = ' ' AND P31.P31_CORP <> '1'))"/*/


	oModel := MPFormModel():New("M0702402", bPreValid,{|oModel| IsValidModel(oModel)}, {|oModel| GRV0702402(oModel)}, NIL)
	oModel:AddFields('SB1MASTER', , oStPai)
	oModel:AddGrid('P17MATRIZ','SB1MASTER', oStMatriz)
	oModel:AddGrid('P17DETAIL','SB1MASTER', oStFilho)

	aCampoP17   := RetCampos("P17")
	nQtdCampo   := Len(aCampoP17)

	For nCampo := 1 To nQtdCampo
		aGatP30P31 := Array(0)
		aGatP30P31 := FwStruTrigger(aCampoP17[nCampo], aCampoP17[nCampo], "U_F1206403('" + aCampoP17[nCampo] + "')", .F., "P17",,,)
		oStFilho:AddTrigger(aGatP30P31[1], aGatP30P31[2], aGatP30P31[3], aGatP30P31[4])
		aGatP30P31 := Nil
	Next nCampo

	AAdd(aP17Rel, {'P17_COD', 'B1_COD'})

	oModel:GetModel('P17MATRIZ'):SetLoadFilter( NIL , cFilMat , NIL )
	oModel:GetModel('P17DETAIL'):SetLoadFilter( NIL , cFilFil , NIL )

	oModel:SetRelation('P17MATRIZ', aP17Rel, P17->(IndexKey(1)))
	oModel:GetModel('P17MATRIZ'):SetUniqueLine({"P17_FILIAL","P17_COD", "P17_FTRATA"})
	oModel:SetRelation('P17DETAIL', aP17Rel, P17->(IndexKey(1)))
	oModel:GetModel('P17DETAIL'):SetUniqueLine({"P17_FILIAL","P17_COD", "P17_FTRATA"})


	oModel:SetDescription("Produto")
	oModel:GetModel('SB1MASTER'):SetDescription('Modelo Produto')
	oModel:GetModel('SB1MASTER'):SetOnlyView()
	oModel:GetModel('P17MATRIZ'):SetDescription('Modelo Tratamento por Filial com Integração')
	oModel:GetModel('P17DETAIL'):SetDescription('Modelo Tratamento por Filial - Administrativo')
	oModel:GetModel('P17MATRIZ'):SetNoInsertLine (.T.)
	oModel:GetModel('P17MATRIZ'):SetNoDeleteLine (.T.)
	oModel:GetModel('P17DETAIL'):SetNoInsertLine (.T.)
	oModel:GetModel('P17DETAIL'):SetNoDeleteLine (.T.)


Return oModel

/*{Protheus.doc} ViewDef
@author Alex Sandro
@since 08/02/2017
@project MAN0000007423041_EF_024
ViewDef reescrito - Thais Paiva 16676552
*/
Static Function ViewDef()
	Local oView		:= Nil
	Local oModel		:= FWLoadModel('F0702402')
	Local oStPai		:= FWFormStruct(2, 'SB1', { |x| ALLTRIM(x) $ 'B1_COD, B1_DESC,B1_LOCPAD,B1_XBLOQ,B1_XFATURA,B1_UM,B1_CONV,B1_TIPCONV,B1_SEGUM,B1_XCONV2,B1_XTCONV2,B1_XTERUM,,B1_XESTOQ,B1_XCONSUM,B1_XCOMP,B1_XP12FRO,B1_XFROP12' })
	Local oStFilho		:= VWStFilho() //FWFormStruct(2, 'P17')
	Local oStMatriz		:= VWStMatriz() //FWFormStruct(2, 'P17')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_SB1',oStPai,'SB1MASTER')
	oView:AddGrid('VIEW_MP17',oStMatriz,'P17MATRIZ')
	oView:AddGrid('VIEW_FP17',oStFilho,'P17DETAIL')

	oView:CreateHorizontalBox('CABEC',30)
	oView:CreateHorizontalBox('GRID',70)

	oView:CreateFolder('PASTAS','GRID')

	oView:AddSheet('PASTAS','ABAMAT','Tratamento por Filial com Integração')
	oView:AddSheet('PASTAS','ABAFIL','Tratamento por Filial - Administrativo')

	oView:CreateHorizontalBox('AREAMAT'		,100,,,'PASTAS','ABAMAT')
	oView:CreateHorizontalBox('AREAFIL'		,100,,,'PASTAS','ABAFIL')

	oView:SetOwnerView('VIEW_SB1', 'CABEC')
	oView:SetOwnerView('VIEW_MP17', 'AREAMAT')
	oView:SetOwnerView('VIEW_FP17', 'AREAFIL')

	oView:EnableTitleView('VIEW_SB1', 'Produto')

	oView:AddUserButton( 'Teste Conversão', 'Teste Conversão', { || U_F0702403() } )

	oView:SetViewProperty("VIEW_MP17", "GRIDDOUBLECLICK", {{|oFormulario, cFieldName, nLineGrid, nLineModel| IIf(AllTrim(cFieldName) == "P17_LEGEND", Legenda(), .T.)}})
	oView:SetViewProperty("VIEW_FP17", "GRIDDOUBLECLICK", {{|oFormulario, cFieldName, nLineGrid, nLineModel| IIf(AllTrim(cFieldName) == "P17_LEGEND", Legenda(), .T.)}})

	oView:SetAfterViewActivate({|| U_F0702406(oView)})

Return oView

/*/{Protheus.doc} RetCampos
Retorna os campos da estrutura conforme prefixo do alias informado.

@project
@type       Static Function
@author     Rafael Riego
@since      10/12/2018
@param      cPrefixo, character, prefixo da tabela
@return     aCampos, array contendo os campos retornados
/*/
Static Function RetCampos(cPrefixo)

	Local aCampos       := {}
	Local aP17Struct    := {}

	Local cCampos       := ""

	Local nCampoP17     := 0
	Local nQtdCmpP17    := 0

	cCampos     := "P17_FILIAL|P17_COD|P17_FTRATA|P17_NFILIA|P17_FILNOM|P17_XUSRIN|P17_XUSRAL|P17_XMIGLT|"

	aP17Struct := P17->(DbStruct())

	nQtdCmpP17 := Len(aP17Struct)

	For nCampoP17 := 1 To nQtdCmpP17
		If !(aP17Struct[nCampoP17][1] $ cCampos) .And. (cPrefixo)->(FieldPos(MudaPrefix(cPrefixo, aP17Struct[nCampoP17][1]))) > 0
			AAdd(aCampos, MudaPrefix(cPrefixo, aP17Struct[nCampoP17][1]))
		EndIf
	Next nCampoP17

Return aCampos

/*/{Protheus.doc} F1206402
Valida alteração do campo e filial de tratamento. Esta rotina está adaptada para ser executada em outras rotinas
ou validações da campos.

@project
@type       Static Function
@author     Rafael Riego
@since      10/12/2018
@param      cFilTrata, character, filial de tratamento
@param      cCampoP17, character, campo alterado
@return     lOk, se permite ou não alteração
/*/
//User Function F1206402(cCampoP17, cFilTrata, lWebserv) Thais Paiva 16676552
User Function F1206402(cCampoP17, cFilTrata, lWebserv,cModel)
	Local aArea := {}
	Local oModel := Nil //Thais Paiva 16676552
	Local lOk   := .T.
	Local oModAlt := Nil //Thais Paiva 16676552
	Local nLinAtu := 1 //Thais Paiva 16676552
	Default cCampoP17   := ""
	Default cFilTrata   := ""
	Default lWebserv    := .F.
	Default cModel := "" //Thais Paiva 16676552

	If !Empty(Alltrim(cModel)) //Início Thais Paiva 16676552
		oModel := FwModelActivate()
		oModAlt := IIF(cModel=="F",oModel:GetModel("P17DETAIL"),oModel:GetModel("P17MATRIZ"))
		nLinAtu := oModAlt:GetLine()
		cFilTrata := oModAlt:GetValue("P17_FTRATA", nLinAtu)
	EndIf //Fim Thais Paiva 16676552

	aArea := {GetArea(), P30->(GetArea()), P31->(GetArea())}

	If Empty(cFilTrata)
		cFilTrata := FwFldGet("P17_FTRATA")
	EndIf

	P30->(DbSetOrder(2))
	P31->(DbSetOrder(2))

	//Caso seja matriz não é necessário validar o campo alterado
	If !(P30->(DbSeek(FwXFilial("P30") + cFilTrata)))
		//Caso não encontre a filial vinculada a uma matriz gera um erro
		If P31->(DbSeek(FwXFilial("P31") + cFilTrata))
			If &("P31->" + MudaPrefix("P31", cCampoP17)) == "2"
				lOk := .F.
				If !lWebserv
					Help("", 1, "HELP", "Filial", "Não é permitido alterar o campo " + AllTrim(cCampoP17) + " diretamente nesta filial de tratamento.",;
						1, 0,,,,,, {""})
				EndIf
			Else
				lOk := .T.
			EndIf
		EndIf
	Else
		lOk := .T.
	EndIf

	AEval(aArea, {|area| RestArea(area)})

Return lOk

/*/{Protheus.doc} F1206403
Função "gatilho" para replicar os dados da matriz em outras filiais.

@project
@type       Static Function
@author     Rafael Riego
@since      06/05/2018
@param      cMatriz, character, Matriz alterada que replicará os dados
@param      cProduto, character, Produto que alterado
@return     Nil
/*/
User Function F1206403(cCampo,cModel)

	Local aArea         := {}
	Local aCamposP31    := {}
	Local aSaveLines    := {}

	Local cMatriz       := ""

	Local nQtdCampos    := 0

	Local oModel        := Nil
	Local oModelP17     := Nil
	Local oView         := Nil

	Local xValor        := 0
	Local nLine         := 0
	Default cModel := "" //Thais Paiva 16676552
	aCamposP31 := RetCampos("P31")
	nQtdCampos := Len(aCamposP31)

	Default cCampo      := ReadVar()

	aArea := {GetArea(), P30->(GetArea()), P31->(GetArea()), P17->(GetArea())}

	oModel      := FwModelActive()

	oView       := FwViewActive()

	cView := oView:ACurrentSelect[1] //Início Thais Paiva 16676552

	If cView == "VIEW_FP17"
		oModelP17   := oModel:GetModel("P17DETAIL")
	Else
		oModelP17   := oModel:GetModel("P17MATRIZ")
	Endif

	cMatriz     := oModelP17:GetValue("P17_FTRATA")
	cProduto    := oModelP17:GetValue("P17_COD")

	P30->(DbSetOrder(2))
	P31->(DbSetOrder(1))
	P17->(DbSetOrder(1))

	xValor  := oModelP17:GetValue(cCampo)
	nLine   := oModelP17:GetLine()

	If AllTrim(MudaPrefix("P31", cCampo)) <> "P31_CODFIL"
		If P17->(DbSeek(FwXFilial("P17") + cProduto + cMatriz))
			If P30->(DbSeek(FwXFilial("P30") + cMatriz)) .And. P30->P30_REPLIC == "1"
				aSaveLines  := FwSaveRows()
				If P31->(DbSeek (FwXFilial("P31") + P30->P30_COD))
					While P31->(!(EoF())) .And. P31->P31_FILIAL == FwXFilial("P30") .And. P31->P31_COD == P30->P30_COD
						If oModelP17:SeekLine({{"P17_FTRATA", P31->P31_CODFIL}})
							If &("P31->" + MudaPrefix("P31", cCampo)) == "2"
								oModelP17:LoadValue(cCampo, xValor)
							EndIf
						EndIf
						P31->(DbSkip())
					End
					FwRestRows(aSaveLines)
					oModelP17:GoLine(nLine)
					If oView != Nil
						//oView:Refresh("VIEW_P17")
						oView:Refresh(cView)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	AEval(aArea, {|area| RestArea(area)})

Return xValor

Static Function MudaPrefix(cPrefixo, cCampo)

	cCampo := cPrefixo + SubStr(cCampo, 4)

Return cCampo

Static Function BuscaP30(cFilP17)

	Local aArea     := {}

	Local cMatriz   := .F.

	aArea := {GetArea(), P30->(GetArea()), P31->(GetArea())}

	P30->(DbSetOrder(2))
	P31->(DbSetOrder(2))
	If P30->(DbSeek(FwXFilial("P30") + cFilP17))
		cMatriz := "1"
	ElseIf P31->(DbSeek(FwXFilial("P31") + cFilP17))
		cMatriz := "2"
	Else
		cMatriz := "3"
	EndIf

	AEval(aArea, {|area| RestArea(area)})

Return cMatriz

Static Function IniP3031(cFilP17)

	Local aArea     := {}

	Local cMatriz   := ""

	P30->(DbSetOrder(2))
	P31->(DbSetOrder(2))
	If P30->(DbSeek(FwXFilial("P30") + cFilP17))
		cMatriz := P30->P30_COD + "P30"
	ElseIf P31->(DbSeek(xFilial("P31") + cFilP17))
		cMatriz := P31->P31_COD + "P31"
	Else
		cMatriz := "999999" + "999"
	EndIf

	AEval(aArea, {|area| RestArea(area)})

Return cMatriz

Static Function Legenda()

	// Cria a legenda que identifica a estrutura
	oLegend := FwLegend():New()

	// Adiciona descrição para cada legenda
	oLegend:Add( { || }, 'BR_VERDE'    , 'Matriz' )
	oLegend:Add( { || }, 'BR_VERMELHO' , 'Filial' )
	oLegend:Add( { || }, 'BR_BRANCO'   , 'Sem Amarração' )

	// Ativa a Legenda
	oLegend:Activate()

	// Exibe a Tela de Legendas
	oLegend:View()

Return .T.

/*/{Protheus.doc} F0702406
Ordena grid da View.

@project
@type       User Function
@author     Rafael Riego
@since      15/05/2019
@param      oView, object, objeto da view
@return     Nil
Reescrito Thais Paiva 16676552
/*/
User Function F0702406(oView)

	Local aSaveRows := {}

	Local nLinha        := 0
	Local nMenor        := 0
	Local nModelLen     := 0
	Local nProxLinha    := 0

	Local oModel    := Nil
	Local oModelFP17 := Nil
	Local oModelMP17 := Nil

	oModel := FwModelActivate()

	If oModel != Nil .And. oView != Nil
		aSaveRows := FwSaveRows()

		oModelMP17 := oModel:GetModel("P17MATRIZ")
		oModelFP17 := oModel:GetModel("P17DETAIL")

		oModel:Activate()

		//ordenação
		nModelLen   := oModelMP17:Length()
		nLinha      := 0

		For nLinha := 1 To nModelLen - 1
			nMenor      := nLinha

			For nProxLinha := nLinha + 1 To nModelLen
				If oModelMP17:GetValue("P30_COD", nProxLinha) < oModelMP17:GetValue("P30_COD", nMenor)
					nMenor := nProxLinha
				Endif
			Next nProxLinha

			oView:LineShift("P17MATRIZ", nLinha, nMenor)

		Next nLinha

		//ordenação
		nModelLen   := oModelFP17:Length()
		nLinha      := 0

		For nLinha := 1 To nModelLen - 1
			nMenor      := nLinha

			For nProxLinha := nLinha + 1 To nModelLen
				If oModelFP17:GetValue("P30_COD", nProxLinha) < oModelFP17:GetValue("P30_COD", nMenor)
					nMenor := nProxLinha
				Endif
			Next nProxLinha

			oView:LineShift("P17DETAIL", nLinha, nMenor)

		Next nLinha

		FwRestRows(aSaveRows)
		oView:Refresh("VIEW_MP17")
		oView:Refresh("VIEW_FP17")
		oModelMP17:GoLine(1)
		oModelFP17:GoLine(1)
	EndIf

Return Nil

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | MDStFilho  | AUTORA| Thais Paiva            | DATA | 25/04/2022    |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Monta os campos da estrutura Tratamento por Filial 	   |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////
Static Function MDStFilho()
	Local nCampo := 0
	Local oStruct := FWFormStruct(1, 'P17')

	oStruct:AddField( ;
		AllTrim('') , ;                 // [01] C Titulo do campo
	AllTrim('Vermelho=Matriz, Verde=Filial') , ;               // [02] C ToolTip do campo
	'P17_LEGEND' , ;                // [03] C identificador (ID) do Field
	'C' , ;                         // [04] C Tipo do campo
	50 , ;                          // [05] N Tamanho do campo
	0 , ;                           // [06] N Decimal do campo
	NIL , ;                         // [07] B Code-block de validação do campo
	NIL , ;                         // [08] B Code-block de validação When do campo
	NIL , ;                         // [09] A Lista de valores permitido do campo
	NIL , ;                          // [10] L Indica se o campo tem preenchimento obrigatório
	{ || IIf( BuscaP30( P17->P17_FTRATA )='1'  , "BR_VERDE" , IF(BuscaP30( P17->P17_FTRATA )='2', "BR_VERMELHO", "BR_BRANCO" )) } , ;           // [11] B Code-block de inicializacao do campo
	NIL , ;                         // [12] L Indica se trata de um campo chave
	NIL , ;                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                           // [14] L Indica se o campo é virtual


	oStruct:AddField( AllTrim('Código Matriz') , ; // [01] C Titulo do campo
	AllTrim('') , ;                                 // [02] C ToolTip do campo
	'P30_COD' , ;                                   // [03] C identificador (ID) do Field
	'C' , ;                                         // [04] C Tipo do campo
	10 , ;                                          // [05] N Tamanho do campo
	0 , ;                                           // [06] N Decimal do campo
	NIL , ;                                         // [07] B Code-block de validação do campo
	NIL , ;                                         // [08] B Code-block de validação When do campo
	NIL , ;                                         // [09] A Lista de valores permitido do campo
	NIL , ;                                         // [10] L Indica se o campo tem preenchimento obrigatório
	{||INIP3031(P17->P17_FTRATA)} , ;               // [11] B Code-block de inicializacao do campo
	.T. , ;                                         // [12] L Indica se trata de um campo chave
	NIL , ;                                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                                           // [14] L Indica se o campo é virtual

	oStruct:AddField(Alltrim(GetSx3Cache("P30_CORP","X3_TITULO")), ; // [01] C Titulo do campo
	Alltrim(GetSx3Cache("P30_CORP","X3_DESCRIC")), ;                                 // [02] C ToolTip do campo
	"P30_CORP" , ;                                   // [03] C identificador (ID) do Field
	GetSx3Cache("P30_CORP","X3_TIPO"), ;                                         // [04] C Tipo do campo
	TamSX3("P30_CORP")[1], ;                                          // [05] N Tamanho do campo
	TamSX3("P30_CORP")[2], ;                                           // [06] N Decimal do campo
	NIL , ;                                         // [07] B Code-block de validação do campo
	NIL , ;                                         // [08] B Code-block de validação When do campo
	NIL , ;                                         // [09] A Lista de valores permitido do campo
	NIL , ;                                         // [10] L Indica se o campo tem preenchimento obrigatório
	{||INICORP(P17->P17_FTRATA)} , ;               // [11] B Code-block de inicializacao do campo
	.T. , ;                                         // [12] L Indica se trata de um campo chave
	NIL , ;                                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                                           // [14] L Indica se o campo é virtual

	aCampoP17   := RetCampos("P17")
	nQtdCampo   := Len(aCampoP17)

	For nCampo := 1 To nQtdCampo
		aGatP30P31 := Array(0)
		aGatP30P31 := FwStruTrigger(aCampoP17[nCampo], aCampoP17[nCampo], "U_F1206403('" + aCampoP17[nCampo] + "','F')", .F., "P17",,,)
		oStruct:AddTrigger(aGatP30P31[1], aGatP30P31[2], aGatP30P31[3], aGatP30P31[4])
		aGatP30P31 := Nil
	Next nCampo

	oStruct:SetProperty( 'P17_FILIAL'	, MODEL_FIELD_WHEN, {||IIF(Alltrim(FwFldGet('B1_MSBLQL'))=='1',.F.,IIF(Alltrim(FwFldGet('P17_ESTOQ'))=='S',.F.,.T.))})
	oStruct:SetProperty( 'P17_FTRATA'	, MODEL_FIELD_WHEN, {||IIF(Alltrim(FwFldGet('B1_MSBLQL'))=='1',.F.,IIF(Alltrim(FwFldGet('P17_ESTOQ'))=='S',.F.,.T.))})

	oStruct:SetProperty( 'P17_ESTOQ'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_ESTOQ","",.F.,"F")})

	oStruct:SetProperty( 'P17_BLOQ'	, MODEL_FIELD_WHEN, {|| U_F1206402("P17_BLOQ","",.F.,"F") .AND. IIF(Alltrim(FwFldGet('B1_MSBLQL'))=='1',.F.,IIF(Alltrim(FwFldGet('P17_ESTOQ'))=='S',.F., U_F1206501(FwFldGet('P17_FTRATA'),FwFldGet('B1_COD'))))})

	oStruct:SetProperty( 'P17_ATUAL'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_ATUAL","",.F.,"F")})

	oStruct:SetProperty( 'P17_UM1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM1","",.F.,"F")})

	oStruct:SetProperty( 'P17_CONV1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONV1","",.F.,"F")})


	oStruct:SetProperty( 'P17_TPC1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_TPC1","",.F.,"F")})

	oStruct:SetProperty( 'P17_UM2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM2","",.F.,"F")})

	oStruct:SetProperty( 'P17_CONV2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONV2","",.F.,"F")})

	oStruct:SetProperty( 'P17_TPC2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_TPC2","",.F.,"F")})

	oStruct:SetProperty( 'P17_UM3'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM3","",.F.,"F")})

	oStruct:SetProperty( 'P17_CONSUM'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONSUM","",.F.,"F")})

	oStruct:SetProperty( 'P17_COMP'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_COMP","",.F.,"F")})

	oStruct:SetProperty( 'P17_P12FRO'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_P12FRO","",.F.,"F")})

	oStruct:SetProperty( 'P17_FROP12'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_FROP12","",.F.,"F")})

	oStruct:SetProperty( 'P17_FATUR'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_FATUR","",.F.,"F")})

	oStruct:SetProperty( 'P17_XBRASC'  , MODEL_FIELD_WHEN, {|| U_F1206402("P17_XBRASC","",.F.,"F")})
	oStruct:SetProperty( 'P17_XSIMPC'  , MODEL_FIELD_WHEN, {|| U_F1206402("P17_XSIMPC","",.F.,"F")})

Return oStruct

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | MDStMatriz  | AUTORA| Thais Paiva           | DATA | 25/04/2022    |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Monta os campos da estrutura Tratamento por Matriz 	   |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////
Static Function MDStMatriz()
	Local nCampo := 0
	Local oStruct := FWFormStruct(1, 'P17')

	oStruct:AddField( ;
		AllTrim('') , ;                 // [01] C Titulo do campo
	AllTrim('Vermelho=Matriz, Verde=Filial') , ;               // [02] C ToolTip do campo
	'P17_LEGEND' , ;                // [03] C identificador (ID) do Field
	'C' , ;                         // [04] C Tipo do campo
	50 , ;                          // [05] N Tamanho do campo
	0 , ;                           // [06] N Decimal do campo
	NIL , ;                         // [07] B Code-block de validação do campo
	NIL , ;                         // [08] B Code-block de validação When do campo
	NIL , ;                         // [09] A Lista de valores permitido do campo
	NIL , ;                          // [10] L Indica se o campo tem preenchimento obrigatório
	{ || IIf( BuscaP30( P17->P17_FTRATA )='1'  , "BR_VERDE" , IF(BuscaP30( P17->P17_FTRATA )='2', "BR_VERMELHO", "BR_BRANCO" )) } , ;           // [11] B Code-block de inicializacao do campo
	NIL , ;                         // [12] L Indica se trata de um campo chave
	NIL , ;                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                           // [14] L Indica se o campo é virtual


	oStruct:AddField( AllTrim('Código Matriz') , ; // [01] C Titulo do campo
	AllTrim('') , ;                                 // [02] C ToolTip do campo
	'P30_COD' , ;                                   // [03] C identificador (ID) do Field
	'C' , ;                                         // [04] C Tipo do campo
	10 , ;                                          // [05] N Tamanho do campo
	0 , ;                                           // [06] N Decimal do campo
	NIL , ;                                         // [07] B Code-block de validação do campo
	NIL , ;                                         // [08] B Code-block de validação When do campo
	NIL , ;                                         // [09] A Lista de valores permitido do campo
	NIL , ;                                         // [10] L Indica se o campo tem preenchimento obrigatório
	{||INIP3031(P17->P17_FTRATA)} , ;               // [11] B Code-block de inicializacao do campo
	.T. , ;                                         // [12] L Indica se trata de um campo chave
	NIL , ;                                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                                           // [14] L Indica se o campo é virtual

	oStruct:AddField(Alltrim(GetSx3Cache("P30_CORP","X3_TITULO")) , ; // [01] C Titulo do campo
	Alltrim(GetSx3Cache("P30_CORP","X3_DESCRIC")), ;                                 // [02] C ToolTip do campo
	"P30_CORP" , ;                                   // [03] C identificador (ID) do Field
	GetSx3Cache("P30_CORP","X3_TIPO"), ;                                         // [04] C Tipo do campo
	TamSX3("P30_CORP")[1], ;                                          // [05] N Tamanho do campo
	TamSX3("P30_CORP")[2], ;                                           // [06] N Decimal do campo
	NIL , ;                                         // [07] B Code-block de validação do campo
	NIL , ;                                         // [08] B Code-block de validação When do campo
	NIL , ;                                         // [09] A Lista de valores permitido do campo
	NIL , ;                                         // [10] L Indica se o campo tem preenchimento obrigatório
	{||INICORP(P17->P17_FTRATA)} , ;               // [11] B Code-block de inicializacao do campo
	.T. , ;                                         // [12] L Indica se trata de um campo chave
	NIL , ;                                         // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )                                           // [14] L Indica se o campo é virtual

	aCampoP17   := RetCampos("P17")
	nQtdCampo   := Len(aCampoP17)

	For nCampo := 1 To nQtdCampo
		aGatP30P31 := Array(0)
		aGatP30P31 := FwStruTrigger(aCampoP17[nCampo], aCampoP17[nCampo], "U_F1206403('" + aCampoP17[nCampo] + "','M')", .F., "P17",,,)
		oStruct:AddTrigger(aGatP30P31[1], aGatP30P31[2], aGatP30P31[3], aGatP30P31[4])
		aGatP30P31 := Nil
	Next nCampo


	oStruct:SetProperty( 'P17_FILIAL'	, MODEL_FIELD_WHEN, {||IIF(FwFldGet('B1_MSBLQL')='1',.F.,IIF(FwFldGet('P17_ESTOQ')='S',.F.,.T.))})
	oStruct:SetProperty( 'P17_FTRATA'	, MODEL_FIELD_WHEN, {||IIF(FwFldGet('B1_MSBLQL')='1',.F.,IIF(FwFldGet('P17_ESTOQ')='S',.F.,.T.))})

	oStruct:SetProperty( 'P17_ESTOQ'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_ESTOQ","",.F.,"M")})

	oStruct:SetProperty( 'P17_BLOQ'	, MODEL_FIELD_WHEN, {|| U_F1206402("P17_BLOQ","",.F.,"M") .AND. IIF(FwFldGet('B1_MSBLQL')='1',.F.,IIF(FwFldGet('P17_ESTOQ')='S',.F., U_F1206501(FwFldGet('P17_FTRATA'),FwFldGet('B1_COD'))))})

	oStruct:SetProperty( 'P17_ATUAL'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_ATUAL","",.F.,"M")})

	oStruct:SetProperty( 'P17_UM1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM1","",.F.,"M")})

	oStruct:SetProperty( 'P17_CONV1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONV1","",.F.,"M")})


	oStruct:SetProperty( 'P17_TPC1'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_TPC1","",.F.,"M")})

	oStruct:SetProperty( 'P17_UM2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM2","",.F.,"M")})

	oStruct:SetProperty( 'P17_CONV2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONV2","",.F.,"M")})

	oStruct:SetProperty( 'P17_TPC2'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_TPC2","",.F.,"M")})

	oStruct:SetProperty( 'P17_UM3'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_UM3","",.F.,"M")})

	oStruct:SetProperty( 'P17_CONSUM'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_CONSUM","",.F.,"M")})

	oStruct:SetProperty( 'P17_COMP'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_COMP","",.F.,"M")})

	oStruct:SetProperty( 'P17_P12FRO'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_P12FRO","",.F.,"M")})

	oStruct:SetProperty( 'P17_FROP12'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_FROP12","",.F.,"M")})

	oStruct:SetProperty( 'P17_FATUR'   , MODEL_FIELD_WHEN, {|| U_F1206402("P17_FATUR","",.F.,"M")})

	oStruct:SetProperty( 'P17_XBRASC'  , MODEL_FIELD_WHEN, {|| U_F1206402("P17_XBRASC","",.F.,"M")})
	oStruct:SetProperty( 'P17_XSIMPC'  , MODEL_FIELD_WHEN, {|| U_F1206402("P17_XSIMPC","",.F.,"M")})

Return oStruct

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | VWStFilho  | AUTORA| Thais Paiva           | DATA | 25/04/2022     |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Estrutura a ser visualizada na aba Tratamento por Filial  |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////
Static Function VWStFilho()
	Local oStruct  := FWFormStruct(2, 'P17')

	oStruct:AddField( ;                    // Ord. Tipo Desc.
	'P17_LEGEND'                    , ;     // [01]  C   Nome do Campo
	"00"                            , ;     // [02]  C   Ordem
	AllTrim( ''    )                , ;     // [03]  C   Titulo do campo
	AllTrim( '' )                   , ;     // [04]  C   Descricao do campo
	{ 'Legenda' }                   , ;     // [05]  A   Array com Help
	'C'                             , ;     // [06]  C   Tipo do campo
	'@BMP'                          , ;     // [07]  C   Picture
	NIL                             , ;     // [08]  B   Bloco de Picture Var
	''                              , ;     // [09]  C   Consulta F3
	.F.                             , ;     // [10]  L   Indica se o campo é alteravel
	NIL                             , ;     // [11]  C   Pasta do campo
	"DADFILIAL"                     , ;     // [12]  C   Agrupamento do campo
	NIL                             , ;     // [13]  A   Lista de valores permitido do campo (Combo)
	NIL                             , ;     // [14]  N   Tamanho maximo da maior opção do combo
	NIL                             , ;     // [15]  C   Inicializador de Browse
	.T.                             , ;     // [16]  L   Indica se o campo é virtual
	NIL                             , ;     // [17]  C   Picture Variavel
	Nil                             )       // [18]  L   Indica pulo de linha após o campo

	oStruct:AddField( ;                    // Ord. Tipo Desc.
	'P30_COD'                       , ;     // [01]  C   Nome do Campo
	"25"                            , ;     // [02]  C   Ordem
	AllTrim( 'COD.P30'    )         , ;     // [03]  C   Titulo do campo
	AllTrim( '' )                   , ;     // [04]  C   Descricao do campo
	{ 'CODIGO P30' }                , ;     // [05]  A   Array com Help
	'C'                             , ;     // [06]  C   Tipo do campo
	'@!'                            , ;     // [07]  C   Picture
	NIL                             , ;     // [08]  B   Bloco de Picture Var
	''                              , ;     // [09]  C   Consulta F3
	.F.                             , ;     // [10]  L   Indica se o campo é alteravel
	NIL                             , ;     // [11]  C   Pasta do campo
	"DADFILIAL"                     , ;     // [12]  C   Agrupamento do campo
	NIL                             , ;     // [13]  A   Lista de valores permitido do campo (Combo)
	NIL                             , ;     // [14]  N   Tamanho maximo da maior opção do combo
	NIL                             , ;     // [15]  C   Inicializador de Browse
	.T.                             , ;     // [16]  L   Indica se o campo é virtual
	NIL                             , ;     // [17]  C   Picture Variavel
	Nil                             )       // [18]  L   Indica pulo de linha após o campo

	oStruct:RemoveField('P17_COD')

Return oStruct

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | VWStMatriz  | AUTORA| Thais Paiva           | DATA | 25/04/2022    |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Estrutura a ser visualizada na aba Tratamento por Matriz  |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////
Static Function VWStMatriz()
	Local oStruct  := FWFormStruct(2, 'P17')

	oStruct:AddField( ;                    // Ord. Tipo Desc.
	'P17_LEGEND'                    , ;     // [01]  C   Nome do Campo
	"00"                            , ;     // [02]  C   Ordem
	AllTrim( ''    )                , ;     // [03]  C   Titulo do campo
	AllTrim( '' )                   , ;     // [04]  C   Descricao do campo
	{ 'Legenda' }                   , ;     // [05]  A   Array com Help
	'C'                             , ;     // [06]  C   Tipo do campo
	'@BMP'                          , ;     // [07]  C   Picture
	NIL                             , ;     // [08]  B   Bloco de Picture Var
	''                              , ;     // [09]  C   Consulta F3
	.F.                             , ;     // [10]  L   Indica se o campo é alteravel
	NIL                             , ;     // [11]  C   Pasta do campo
	"DADMATRIZ"                     , ;     // [12]  C   Agrupamento do campo
	NIL                  			, ;     // [13]  A   Lista de valores permitido do campo (Combo)
	NIL                             , ;     // [14]  N   Tamanho maximo da maior opção do combo
	NIL                             , ;     // [15]  C   Inicializador de Browse
	.T.                             , ;     // [16]  L   Indica se o campo é virtual
	NIL                             , ;     // [17]  C   Picture Variavel
	Nil                             )       // [18]  L   Indica pulo de linha após o campo

	oStruct:AddField( ;                    // Ord. Tipo Desc.
	'P30_COD'                       , ;     // [01]  C   Nome do Campo
	"25"                            , ;     // [02]  C   Ordem
	AllTrim( 'COD.P30'    )         , ;     // [03]  C   Titulo do campo
	AllTrim( '' )                   , ;     // [04]  C   Descricao do campo
	{ 'CODIGO P30' }                , ;     // [05]  A   Array com Help
	'C'                             , ;     // [06]  C   Tipo do campo
	'@!'                            , ;     // [07]  C   Picture
	NIL                             , ;     // [08]  B   Bloco de Picture Var
	''                              , ;     // [09]  C   Consulta F3
	.F.                             , ;     // [10]  L   Indica se o campo é alteravel
	NIL                             , ;     // [11]  C   Pasta do campo
	"DADMATRIZ"                     , ;     // [12]  C   Agrupamento do campo
	NIL                             , ;     // [13]  A   Lista de valores permitido do campo (Combo)
	NIL                             , ;     // [14]  N   Tamanho maximo da maior opção do combo
	NIL                             , ;     // [15]  C   Inicializador de Browse
	.T.                             , ;     // [16]  L   Indica se o campo é virtual
	NIL                             , ;     // [17]  C   Picture Variavel
	Nil                             )       // [18]  L   Indica pulo de linha após o campo

	oStruct:RemoveField('P17_COD')

Return oStruct

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | INICORP		| AUTORA| Thais Paiva           | DATA | 26/04/2022    |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Preenchimento do campo P30_CORP					       |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////
Static Function INICORP(cFilP17)
	Local aArea     := {}
	Local cMatriz   := ""

	P30->(DbSetOrder(2))
	If P30->(DbSeek(FwXFilial("P30") + cFilP17))
		If P30->P30_CORP == "1"
			cMatriz := "1"
		Else
			cMatriz := "2"
		EndIf
	Else
		cMatriz := "2"
	EndIf

	AEval(aArea, {|area| RestArea(area)})

Return cMatriz

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | GRV0702402  | AUTORA| Thais Paiva           | DATA | 27/04/2022    |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Função: Gravação/Exclusão de informações adicionais		       |//
//+--------------------------------------------------------------------------------+//
//| CHAMADO    | 1244366 - DOR08899643   										   |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////

Static Function GRV0702402(oModAtu)
	Local aAreaGrv := GetArea()
	Local nI := 0
	Local _cCodigo := ""
	Local _aFilDel := {}
	Local cBloqDel := GetNewPar("FS_XBLQP17","1")

	DbSelectArea("P17")
	DbSetOrder(1)
	For nI := 1 To oModAtu:GetModel('P17MATRIZ'):Length()
		oModAtu:GetModel('P17MATRIZ'):GoLine( nI )

		If cBloqDel == "1" .And. oModAtu:GetModel('P17MATRIZ'):IsDeleted()
			oModAtu:SetErrorMessage("P17MATRIZ", ,,,"Cadastro P17","Não é permitido deletar itens no GRID da tabela.","Volte o status do item para ativo.")
			//Help(NIL, NIL, "Cadastro P17", NIL, "Não é permitido deletar itens no GRID da tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Volte o status do item para ativo."})
			Return .F.
		EndIf
		If oModAtu:GetModel('P17MATRIZ'):IsDeleted()
			If DbSeek(FwXFilial("P17") + oModAtu:GetModel('P17MATRIZ'):GetValue("P17_COD") + oModAtu:GetModel('P17MATRIZ'):GetValue("P17_FTRATA"))
				RecLock("P17", .F.)
				P17->(DbDelete())
				P17->(MsUnLock())
			EndIf
			DbSelectArea("P30")
			DbSetOrder(2)
			If DbSeek(FwXFilial("P30") + oModAtu:GetModel('P17MATRIZ'):GetValue("P17_FTRATA"))
				_cCodigo := P30->P30_COD
				DbSelectArea("P31")
				DbSetOrder(1)
				If DbSeek(FwXFilial("P31") + _cCodigo)
					While P31->(!EOF()) .AND. Alltrim(P31->P31_COD) == Alltrim(_cCodigo)
						aAdd(_aFilDel,{oModAtu:GetModel('P17MATRIZ'):GetValue("P17_COD"),P31->P31_CODFIL})
						P31->(DbSkip())
					EndDo
				EndIf
				P31->(DbCloseArea())
			EndIf
			P30->(DbCloseArea())
		Else
			FwFormCommit(oModAtu)
		EndIf
	Next nI

	DbSelectArea("P17")
	DbSetOrder(1)
	For nI := 1 To oModAtu:GetModel('P17DETAIL'):Length()
		oModAtu:GetModel('P17DETAIL'):GoLine( nI )

		If cBloqDel == "1" .And. oModAtu:GetModel('P17DETAIL'):IsDeleted()
			oModAtu:SetErrorMessage("P17MATRIZ", ,,,"Cadastro P17","Não é permitido deletar itens no GRID da tabela.","Volte o status do item para ativo.")
			//Help(NIL, NIL, "Cadastro P17", NIL, "Não é permitido deletar itens no GRID da tabela.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Volte o status do item para ativo."})
			Return .F.
		EndIf
		If oModAtu:GetModel('P17DETAIL'):IsDeleted()
			If DbSeek(FwXFilial("P17") + oModAtu:GetModel('P17DETAIL'):GetValue("P17_COD") + oModAtu:GetModel('P17DETAIL'):GetValue("P17_FTRATA"))
				RecLock("P17", .F.)
				P17->(DbDelete())
				P17->(MsUnLock())
			EndIf
		Else
			FwFormCommit(oModAtu)
		EndIf
	Next nI

	If Len(_aFilDel) > 0
		DbSelectArea("P17")
		DbSetOrder(1)
		For nI := 1 to Len(_aFilDel)
			If DbSeek(FwXFilial("P17") + _aFilDel[nI][1] + _aFilDel[nI][2])
				RecLock("P17", .F.)
				P17->(DbDelete())
				P17->(MsUnLock())
			EndIf
		Next nI
		MsgAlert("A(s) Filiai(s) associada(s) ao(s) Front(s) excluído(s) também foi(ram) excluída(s).")
	EndIf

	RestArea(aAreaGrv)
Return .T.

Static Function IsValidModel(oModel)

	Local nOperation	:= oModel:GetOperation()
	Local oModelB1      := oModel:GetModel('SB1MASTER')
	Local oModelP17     := oModel:GetModel('P17DETAIL')
	Local lRet          := .T.

	If !Empty(oModelB1:GetValue("B1_XSIMPRO"))
		If oModelP17:Getvalue("P17_XSIMPC") == 0
			lRet := .F.
			Help(" ", 1, "Problema", , "O campo Conv Simpro deve ser preenchido quando o código Simpro é informado.", 1, 0, , , , , , {"Informe o valor de conversão no campo Conv Simpro"})
		EndIf
	ElseIf !Empty(oModelB1:GetValue("B1_XBRASIN"))
		If oModelP17:GetValue("P17_XBRASC") == 0
			lRet := .F.
			Help(" ", 1, "Problema", , "O campo Conv Brasind deve ser preenchido quando o código Brasindice é informado.", 1, 0, , , , , , {"Informe o valor de conversão no campo Conv Brasind"})
		EndIf
	EndIf

Return lRet
