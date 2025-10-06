#INCLUDE "AE_Despv_Ap6.ch"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �AE_DESP   �Autor  �Armando / Willy     � Data �  09/06/02   ���
�������������������������������������������������������������������������͹��
���Desc.     � Manuten��o do Cadastro de Despesas.                        ���
�������������������������������������������������������������������������͹��
���Uso       � AP6                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Template Function AE_Desp()

Local cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

ChkTemplate("CDV")

AxCadastro('LHS','Cadastro de Despesas', 'T_VldExcDp()',cVldAlt)

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �AE_DESP   �Autor  �Diogo Vieira        � Data �  21/08/2018 ���
�������������������������������������������������������������������������͹��
���Desc.     �  Valida Exclus�o                                           ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Template Function VldExcDp()

Local cCodDes:= LHS->LHS_CODIGO 
Local lRet := .T.
Local cAliasTrb :="TMPLHR"
Local aSaveArea := GetArea()  

	BeginSql Alias cAliasTrb 
		SELECT LHR_CODDES 
		FROM %table:LHR%
	    WHERE LHR_FILIAL = %xFilial:LHR% 
		AND LHR_CODDES = %exp:cCodDes% 
		AND %NotDel%
	EndSQL
	
	If (cAliasTrb)->(! Eof())
		MsgInfo(STR0023)
		lRet := .F.		
	EndIf
	
  (cAliasTrb)->(DbCloseArea())
  
RestArea(aSaveArea)   

Return lRet