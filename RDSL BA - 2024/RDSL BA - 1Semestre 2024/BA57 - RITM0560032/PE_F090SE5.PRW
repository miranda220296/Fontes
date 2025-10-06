#include 'totvs.ch'

/* {Protheus.doc} F090SE5
Ponto de Entrada p/ gravação de movimentação bancários processados
@type function
@return */


User Function F090SE5()
    Local aRecno := ParamIxb[1]
    Local nCntFor :=0
 
    dbSelectArea("SE5")
    DbSetOrder(1)
    For nCntFor := 1 to Len(aRecno)
        SE5->(dbGoto(aRecno[nCntFor]))

        U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)

    Next nCntFor
Return
