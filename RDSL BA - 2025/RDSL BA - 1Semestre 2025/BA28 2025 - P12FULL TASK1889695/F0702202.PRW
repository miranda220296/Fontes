#INCLUDE "TOTVS.CH"

/*{Protheus.doc} F0702202
FUNCOES DE VALIDACAO PARA MAN0000007423041_EF_022
Função responsável por validar:
    - Mesmo tipo de produto em relação à Estocável
    - Não bloqueado
    - Apenas produtos integráveis
@author robson.william
@since 02/03/2017
@project	MAN0000007423041_EF_022
@return lRet
*/ 
User Function F0702202()

	Local cCodProd := GdFieldGet("C7_PRODUTO")
	Local lRet     := .T.

	If GdDeleted()
		Return lRet
	EndIf

	If !IsInCallStack("U_F1200600")
		lRet := U_F1200902()
	EndIf

	If IsBlind()
		Return lRet
	Endif

	If lRet .and. !VldEstoc(cCodProd)
		Help(, ,"F0702202 - Produto Estocável", ,"Produto Estocável e Produto Não Estocável não podem estar no mesmo pedido.", 1, 0)
		lRet := .F.
	EndIf

	If lRet .and. !VldBloq(cCodProd)
		Help(, ,"F0702202 - Produto Bloqueado", ,"Não é permitido utilizar Produto Bloqueado.", 1, 0)
		lRet := .F.
	EndIf

	If lRet .and. !VldGrupo(cCodProd)
		Help(, ,"F0702202 - Grupo Produtos Não Integrável", ,"Grupo de Produtos Integrável e Não Integrável não podem estar no mesmo pedido.", 1, 0)
		lRet := .F.
	EndIf

	If lRet .and. !VldAltP17(cCodProd)
		Help(, ,"F0702202 - Alteração não permitida!", ,"Não é possível incluir um produto não estocável em um pedido originalmente criado com produto estocável, ou vice-versa, é necessário eliminar resíduo do pedido atual e criá-lo novamente com os itens desejados.", 1, 0)
		lRet := .F.
	EndIf

Return lRet


Static Function VldEstoc(cCodProd)

	Local lValido  := .T.
	Local cEstoc   := ""
	Local nPosProd := AScan(aHeader, { |x| AllTrim(Upper(x[2])) == AllTrim(Upper("C7_PRODUTO"))})
	Local nI       := 0

	Default cCodProd = ""

	If !Empty(cCodProd)
		cEstoc	:= P17->(Posicione("P17", 1, xFilial("P17") + cCodProd + cFilAnt, "P17_ESTOQ"))
		For nI := 1 to Len(aCols)
			If !aCols[nI][Len(aCols[nI])] .And. !P17->(Posicione("P17", 1, xFilial("P17") + aCols[nI, nPosProd] + cFilAnt, "P17_ESTOQ") == cEstoc)
				lValido := .F.
				Exit
			EndIf
		Next
	EndIf

Return lValido

Static Function VldBloq(cCodProd)

	Local lValido := .T.

	Default cCodProd = ""

	If !Empty(cCodProd)
		If (P17->(Posicione("P17", 1, xFilial("P17") + cCodProd + cFilAnt, "P17_BLOQ")) == "S")
			lValido := .F.
		EndIf
	EndIf

Return lValido

Static Function VldGrupo(cProduto)

	Local lValido  := .T.
	Local lIntPC   := .F.
	Local nPosProd := AScan(aHeader, { |x| AllTrim(Upper(x[2])) == AllTrim(Upper("C7_PRODUTO"))})
	Local nI       := 0

	If !Empty(cProduto)
		lIntPC := IsGrpInt(cProduto)

		For nI := 1 to Len(aCols)
			If lIntPC != IsGrpInt(aCols[nI, nPosProd])
				lValido := .F.
				Exit
			Endif
		Next
	EndIf

Return lValido

Static Function IsGrpInt(cProduto)

	Local lIntegra := .F.
	Local cGruProd := SuperGetMv("FS_GRPPC", .F., "")

	cGrupoLin := Posicione("SB1", 1, xFilial("SB1") + cProduto, "B1_GRUPO")
	If cGrupoLin $ cGruProd
		lIntegra := .T.
	Endif

Return lIntegra


Static Function VldAltP17(cCodProd)

	Local lValido  := .T.
	Local cEstoc   := ""
	Local cEstoc2  := "" //Produto que está salvo no pedido atualmente.
	Local nPosProd := AScan(aHeader, { |x| AllTrim(Upper(x[2])) == AllTrim(Upper("C7_PRODUTO"))})
	Local nI       := 0

	If !ALTERA
		Return lValido
	EndIf

	If Posicione("SC7", 1, cFilant+cA120NUM, "C7_CONAPRO") <> 'L' .And. Empty(AllTrim(Posicione("SC7", 1, cFilant+cA120NUM, "C7_XNUM")))
		Return lValido
	EndIf


	If !Empty(cCodProd)
		cEstoc	:= P17->(Posicione("P17", 1, xFilial("P17") + cCodProd + cFilAnt, "P17_ESTOQ"))
		cEstoc2 := P17->(Posicione("P17", 1, xFilial("P17") + P17->(Posicione("SC7", 1, cFilant+cA120NUM, "C7_PRODUTO")) + cFilAnt, "P17_ESTOQ"))

		If cEstoc <> cEstoc2
			lValido := .F. //Valida se o produto original era estocável ou não, e se o novo produto também é. Se for diferente, não permite alterar.
		EndIF
	EndIf

Return lValido
