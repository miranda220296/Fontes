#include 'totvs.ch'

/* {Protheus.doc} FA050FIN
Ponto de Entrada p/ gravação de movimentação na inclusão de tit. no Contas a Pagar

@return */

User Function FA050FIN()
 
DbSelectArea("SE5")
DbSetOrder(7)
If DbSeek(xFilial("SE5")+SE2->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA))
    U_MSLOGE5(1)//Chamada para gravar LOG de usuário na tabela SE5 (operação inclusão)
EndIf 

Return 

