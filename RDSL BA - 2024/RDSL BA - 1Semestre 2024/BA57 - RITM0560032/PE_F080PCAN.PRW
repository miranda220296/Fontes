#include 'totvs.ch'

/* {Protheus.doc} F080PCAN
Ponto de Entrada p/ gravação de movimentação bancários processados para canc. de baixa
@type function
@return */

User Function F080PCAN() 

If SE5->E5_RECPAG == 'R'
	U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)
EndIf
If !Empty(Alltrim(SE5->E5_XLOGALT)) .AND. SE5->E5_RECONC <> 'x'
    U_MSLOGE5(2)//Chamada para gravar LOG de usuário na tabela SE5 (operação Deleção)
EndIf



Return

