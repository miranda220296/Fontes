#INCLUDE "AE_AtuLogin_AP7.ch"
#INCLUDE "Protheus.ch"

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �AE_AtuLogin�Autor  � Willy              � Data �  10/04/03  ���
�������������������������������������������������������������������������͹��
���Desc.     �  Atualiza os logins do cadastros de viagens,para presta��o ���
���          �  de contas.                                                ���
�������������������������������������������������������������������������͹��
���Uso       � AP7                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function AE_AtuLogin()

Local _cperg := STR0001 //"Deseja Atualizar o Login do Cadastro de Viagem, para as Presta��es de Contas ?"

chktemplate("CDV")

If MsgYESNO(_cperg, STR0002) //"Aten��o"
	MsgRun(STR0003,"",{|| CursorWait(), ExecLogin() ,CursorArrow()}) //'Atualizando Login, Aguarde...'
	MsgInfo(STR0004) //"Atualiza��o do Login, Concluida com Sucesso !"
Endif

Return
*--------------------------------------------------------------------------------------

*--------------------------------------------------------------------------------------
Static Function ExecLogin()
*--------------------------------------------------------------------------------------

Local _aAreaLHQ:= GetArea()

DbSelectArea('LHQ')
DbSetOrder(4)
DbGotop()
Do While !Eof()
	DbSelectArea('LHT')
	DbSetOrder(1)
	If MsSeek(xFilial('LHT') + LHQ->LHQ_FUNC)
		RecLock('LHQ',.F.) 
		LHQ->LHQ_LOGIN := LHT->LHT_LOGIN
		MsUnLock('LHQ')
	EndIf
	DbSelectArea('LHQ')
	LHQ->(DbSkip())
EndDo

RestArea(_aAreaLHQ)

Return
