#Include 'totvs.ch'
/*
|----------------------------------------------------------------------------|
|Programa  |Mt110LOk  |Autor  |TECNOSUM            | Data |  14/04/2016      |
|----------------------------------------------------------------------------|
|Descrição |Validação do Linha OK na solicitação de comras		             |
|          |Valida se só existe o mesmo motivo em todas as linahs            |					  
|----------------------------------------------------------------------------|
|Uso       |REDEDOR                                                          |						  
|----------------------------------------------------------------------------|
*/
User Function Mt110LOk()

	Local nPMotivo 	:= aScan(aHeader, {|x| AllTrim(x[2]) == 'C1_XMOTIVO'})
	Local nPTipo	:= aScan(aHeader, {|x| AllTrim(x[2]) == 'C1_XTPSC'})
	Local lRet := .T.
	Local nDelete := Len(aHeader)+1 //posicao que define se linha esta deletada
	Local nPosReq  	:= ASCAN(aHeader,{|x| AllTrim(x[2]) == "C1_XTPREQ"}) //Thais Paiva - 20390232/20856688
	Local nProduto  := aScan(aHeader, {|x| AllTrim(x[2]) == 'C1_PRODUTO'})
	Local nPPlanexo := aScan(aHeader, {|x| AllTrim(x[2]) == 'C1_XIDPLAN'})

//--[ ID 1473 ]------------------------
//CC1XTOTAL := U_F1206003()
	CC1XTOTAL := U_F1206004()
//-------------------------------------

	If n == 1
		If !(aCols[n][nDelete])
			IF !U_RDDV002(aCols[n][nPTipo], aCols[n][nPMotivo])
				lRet := .F.
				//Exit
			Endif
			IF !U_RDDV001(aCols[n][nPTipo])
				lRet := .F.
				//Exit
			Endif
			/*/IF !U_BLQEMERG(aCols[n][nProduto], aCols[n][nPTipo], aCols[n][nPMotivo], aCols[n][nPPlanexo])
				lRet := .F.
			Endif/*/
			IF !U_RDDV004(aCols[n][nPTipo], aCols[n][nPosReq]) //Thais Paiva - 20390232/20856688
				lRet := .F. //Thais Paiva - 20390232/20856688
			Endif //Thais Paiva - 20390232/20856688
		EndIf
	Else
		//For nX := 1 To Len(aCols)
		If !(aCols[n][nDelete]) .And. !(aCols[n - 1][nDelete])
			If aCols[n][nPTipo] <> aCols[n - 1][nPTipo]
				lRet := .F.
				If l110Auto //Thais Paiva - 20390232/20856688
					aadd(_aMsgErr,"Todos os itens devem ser do mesmo Tipo de SC! Verifique!") //Thais Paiva - 20390232/20856688
				Else //Thais Paiva - 20390232/20856688
					Alert("Todos os itens devem ser do mesmo Tipo de SC! Verifique!")
				EndIf //Thais Paiva - 20390232/20856688
				//Exit
			Endif
			If Alltrim(aCols[n][nPosReq]) <> Alltrim(aCols[n - 1][nPosReq]) .AND. !(IsInCallStack('U_REDA003')) //Início - Thais Paiva - 20390232/20856688
				lRet := .F.
				If l110Auto
					aadd(_aMsgErr,"Todos os itens devem ser do mesmo Tipo de Requisição! Verifique!")
				Else
					Alert("Todos os itens devem ser do mesmo Tipo de Requisição! Verifique!")
				Endif
			Endif //Fim - Thais Paiva - 20390232/20856688
			IF !U_RDDV002(aCols[n][nPTipo], aCols[n][nPMotivo])
				lRet := .F.
				//Exit
			Endif
			// ------------------------------------



			// ------------------------------------
			// @Author
			// @Since
			// ------------------------------------
			// VErifica se o Solicitante tem permissao para incluir SC do tipo informado
			// ------------------------------------
			IF !U_RDDV001(aCols[n][nPTipo])
				lRet := .F.
				//Exit
			Endif
			// ------------------------------------



			// ------------------------------------
			// BLOCO NOVO
			// @Author  Sato
			// @Since   25/01/2024
			// ------------------------------------
			// Verifica a regra de Bloqueio de SC Emergencial
			// ------------------------------------
			/*/IF !U_BLQEMERG(aCols[n][nProduto], aCols[n][nPTipo], aCols[n][nPMotivo], aCols[n][nPPlanexo])
				lRet := .F.
			Endif/*/
			// ------------------------------------
			IF !U_RDDV004(aCols[n][nPTipo], aCols[n][nPosReq]) //Thais Paiva - 20390232/20856688
				lRet := .F. //Thais Paiva - 20390232/20856688
			Endif //Thais Paiva - 20390232/20856688
		EndIf
		//Next
	EndIf

Return(lRet)
