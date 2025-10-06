#INCLUDE "AE_Colab_AP7.ch"
#INCLUDE "Protheus.ch"

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �AE_COLAB  �Autor  �Willy               � Data �  24/03/03   ���
�������������������������������������������������������������������������͹��
���Desc.     � Manuten��o do Cadastro de Colaboradores.                   ���
�������������������������������������������������������������������������͹��
���Uso       �Template CDV - Controle de Despesas de Vaigens 			  ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

User Function AE_Colab()
Local cVldAlt := "U_ValAltCol()" // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Local cVldExc := "U_VldExcCol()" // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

ChkTemplate("CDV")

AxCadastro('LHT', STR0001,cVldExc,cVldAlt) //'Cadastro de Colaboradores'

Return

//***********************************************************************************************************/
//Validacao da Exclusao do Hotel - Se estiver relacionada com alguma solicitacao nao sera apagada
//***********************************************************************************************************/
User Function ValAltCol()
Local lRet := .T., _aArea := GetArea()
Local cBanco := LEFT(M->LHT_BCDEPS, 3), cAgencia := RIGHT(M->LHT_BCDEPS, 5), cNumCon := LHT_CTDEPS

DbSelectArea("SA2")
DbSetOrder(8) //A2_FILIAL+A2_MAT
If (DbSeek(xFilial() + LHT->LHT_CODMAT))
	RecLock("SA2", .F.)
		SA2->A2_BANCO 	:= cBanco
		SA2->A2_AGENCIA	:= cAgencia
		SA2->A2_NUMCON 	:= cNumCon
	MsUnlock()
EndIf

RestArea(_aArea)
Return lRet

/*
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������ͻ��
���Programa  �VldExcCol �Autor  �Pablo Gollan Carreras� Data �  25/01/10   ���
��������������������������������������������������������������������������͹��
���Desc.     �Validacao de exclusao para o AxCadastro                      ���
���          �                                                             ���
��������������������������������������������������������������������������͹��
���Uso       �CDV-AE_COLAB                                                 ���
��������������������������������������������������������������������������ͼ��
������������������������������������������������������������������������������
������������������������������������������������������������������������������
*/

User Function VldExcCol()

Local lRet		:= .T.
Local aArea		:= GetArea()
Local cMsgAl	:= ""
Local aMsg		:= {}
Local ni		:= 0
Local cArq		:= Nil       
Local nIdx		:= 0

//Verificacao  de solicitador
dbSelectArea("LHP")
LHP->(dbSetOrder(3))
If LHP->(dbSeek(xFilial("LHP") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0002)) //"Est� associado a solicita��es de viagem como solicitante."
	lRet := .F.	
Endif

//LHP - Verificacao de aprovador I
LHP->(dbSetOrder(5))
If LHP->(dbSeek(xFilial("LHP") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0003)) //"Est� associado a solicita��es de viagem como aprovador I."
	lRet := .F.			
Endif

//LHP - Verificacao de aprovador II
cArq := CriaTrab(Nil,.F.)
IndRegua("LHP",cArq,"LHP_FILIAL+LHP_DGRAR",,"")
dbSelectArea("LHP")
nIdx := RetIndex("LHP")
//#IFNDEF TOP
//	dbSetIndex(cArq + OrdBagExt())
//#ENDIF
LHP->(dbSetOrder(nIdx+1))
If LHP->(dbSeek(xFilial("LHP") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0004)) //"Est� associado a solicita��es de viagem como aprovador II."
	lRet := .F.			
Endif
RetIndex("LHP")
fErase(cArq + OrdBagExt())

//LHP - Verificao despesa viagem - solicitante
cArq := CriaTrab(Nil,.F.)
IndRegua("LHQ",cArq,"LHQ_FILIAL+LHQ_FUNC",,"")
dbSelectArea("LHQ")
nIdx := RetIndex("LHQ")
//#IFNDEF TOP
//	dbSetIndex(cArq + OrdBagExt())
//#ENDIF
LHQ->(dbSetOrder(nIdx+1))
If LHQ->(dbSeek(xFilial("LHQ") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0005)) //"Est� associado a despesas de viagem como solicitante."
	lRet := .F.			
Endif
RetIndex("LHQ")
fErase(cArq + OrdBagExt())

//LHQ - Verificao despesa viagem - aprovador I
cArq := CriaTrab(Nil,.F.)
IndRegua("LHQ",cArq,"LHQ_FILIAL+LHQ_SUPIMD",,"")
dbSelectArea("LHQ")
nIdx := RetIndex("LHQ")
//#IFNDEF TOP
//	dbSetIndex(cArq + OrdBagExt())
//#ENDIF
LHQ->(dbSetOrder(nIdx+1))
If LHQ->(dbSeek(xFilial("LHQ") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0006)) //"Est� associado a despesas de viagem como aprovador I."
	lRet := .F.			
Endif
RetIndex("LHQ")
fErase(cArq + OrdBagExt())

//LHQ - Verificao despesa viagem - aprovador II
cArq := CriaTrab(Nil,.F.)
IndRegua("LHQ",cArq,"LHQ_FILIAL+LHQ_DGRAR",,"")
dbSelectArea("LHQ")
nIdx := RetIndex("LHQ")
//#IFNDEF TOP
//	dbSetIndex(cArq + OrdBagExt())
//#ENDIF
LHQ->(dbSetOrder(nIdx+1))
If LHQ->(dbSeek(xFilial("LHQ") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0007)) //"Est� associado a despesas de viagem como aprovador II."
	lRet := .F.			
Endif
RetIndex("LHQ")
fErase(cArq + OrdBagExt())

//LJI - Autorizacao uso de despesa por funcionario
dbSelectArea("LJI")
LJI->(dbSetOrder(1))
If LJI->(dbSeek(xFilial("LJI") + LHT->LHT_CODMAT))
	aAdd(aMsg,OemToAnsi(STR0008)) //"Est� associado a lista de autorizacao de uso de despesa por funcion�rio."
	lRet := .F.			
Endif

If !lRet
	For ni := 1 to Len(aMsg) Step 1
		cMsgAl += AllTrim(Str(ni) + ". " + aMsg[ni]) + IIf(ni < Len(aMsg),Replicate(CRLF,2),"")
	Next ni
	MsgAlert(OemToAnsi(STR0009 + AllTrim(LHT->LHT_NOME) + " (" + AllTrim(LHT->LHT_CODMAT) + ") " + STR0010) + CRLF + CRLF + cMsgAl) //"O colaborador " //"n�o pode ser exclu�do pois:"
Endif
RestArea(aArea)

Return lRet
