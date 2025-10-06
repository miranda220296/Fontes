#INCLUDE 'TOTVS.CH'

#Define INCLUI_PREV 01
#Define ALTERA_PREV 02
#Define EXCLUI_PREV 03
#Define ENVBAN_PREV 04
#Define REJBAN_PREV 05
#Define BAIXAT_PREV 06
#Define ESTBXA_PREV 07
#Define GRVCHQ_PREV 08
#Define ESTCHQ_PREV 09
#Define ENVBAN_REAL 21
#Define REJBAN_REAL 22
#Define BAIXAT_REAL 23
#Define ESTBXA_REAL 24
#Define GRVCHQ_REAL 31
#Define ESTCHQ_REAL 32
#Define PAGADT_REAL 41
#Define RECADT_REAL 42

/*/{Protheus.doc} User Function F390CBX2
    Ponto localizado no cancelamento do cheque, depois de remover do título
    @type  Function
    /*/
User Function F390CBX2()

	DbSelectArea("SE5")
	DbSetOrder(11)
	If DbSeek(xFilial('SE5')+SEF->(EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM+DTOS(EF_DATA)))
		U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)
	EndIf

Return
