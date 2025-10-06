#include 'totvs.ch'

/* {Protheus.doc} FA050FIN
Ponto de Entrada p/ grava��o de movimenta��o na inclus�o de tit. no Contas a Pagar

@return */

User Function FA050FIN()
 
DbSelectArea("SE5")
DbSetOrder(7)
If DbSeek(xFilial("SE5")+SE2->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA))
    U_MSLOGE5(1)//Chamada para gravar LOG de usu�rio na tabela SE5 (opera��o inclus�o)
EndIf 

Return 

