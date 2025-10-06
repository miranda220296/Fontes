//#INCLUDE "PROTHEUS.CH"
#INCLUDE "rwmake.ch"

/*
|----------------------------------------------------------------------------|
|Programa  |RDDA002  |Autor  |TECNOSUM            | Data |  31/03/2016       |
|----------------------------------------------------------------------------|
|Descrição |Amarração Tipo SC x Grupo de Aprovação                        	 |						  
|----------------------------------------------------------------------------|
|Uso       |REDEDOR                                                          |						  
|----------------------------------------------------------------------------|
|Alteração |Adequações às novas Regras - 20390232/20856688 - Thais Paiva     |
|----------------------------------------------------------------------------|
*/


User Function RDDA002()
Local oCadTpSc
Private cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Private cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
Private cCadastro := "Amarração Tipo SC x Grupo de Aprovação"
Private cString := "PZY"

DbSelectArea(cString)
DbSetOrder(1)
DbGoTop()
//AxCadastro(cString,"Amarração Tipo SC x Grupo de Aprovação",cVldExc,cVldAlt)
oCadTpSc:= FWMBrowse():New()
oCadTpSc:SetAlias(cString)
oCadTpSc:SetMenuDef("RDDA002")
oCadTpSc:SetDescription(cCadastro)
oCadTpSc:SetFilterDefault("PZY_FILIAL ==  xFilial('PZY')" )

oCadTpSc:Activate()

Return

//-------------------------------------------------------------------
//{Protheus.doc} MenuDef
//-------------------------------------------------------------------
Static Function MenuDef()
Local aMenu := {}

aAdd(aMenu,{"Visualizar","VIEWDEF.RDDA002",0,2})
aAdd(aMenu,{"Incluir"	,"VIEWDEF.RDDA002",0,3})
aAdd(aMenu,{"Alterar"	,"VIEWDEF.RDDA002",0,4})
aAdd(aMenu,{"Excluir"	,"VIEWDEF.RDDA002",0,5})
 
Return aMenu

//-------------------------------------------------------------------
//{Protheus.doc} ModelDef
//-------------------------------------------------------------------
Static Function ModelDef()  
Local oStruPZY := FWFormStruct(1,cString)
Local oModPZY := Nil

//-----------------------------------------
//Monta o modelo do formulário
//----------------------------------------- 
oModPZY := MPFormModel():New("MDDA002",/*Pré-Validação*/,/*Pos-Validacao*/,/*Commit*/,/*Cancel*/) 
oModPZY:AddFields("PZYMASTER",/*cOwner*/,oStruPZY)
oModPZY:SetDescription(cCadastro)
oModPZY:GetModel("PZYMASTER"):SetDescription(cCadastro)
oModPZY:GetModel("PZYMASTER"):SetPrimaryKey({"PZY_FILIAL", "PZY_TIPOSC", "PZY_XTPREQ", "PZY_GRAPRO" })
                                                                               
Return oModPZY 

//-------------------------------------------------------------------
//{Protheus.doc} ViewDef
//-------------------------------------------------------------------
Static Function ViewDef()
Local oModPZY := FWLoadModel("RDDA002")
Local oStruPZY := FWFormStruct(2,cString)
Local oViewPZY := Nil

oViewPZY := FWFormView():New()
oViewPZY:SetModel(oModPZY)
oViewPZY:AddField('VIEW_PZY', oStruPZY, 'PZYMASTER')
oViewPZY:CreateHorizontalBox('TELA' , 100)
oViewPZY:SetOwnerView('VIEW_PZY', 'TELA')

Return oViewPZY

/*
|----------------------------------------------------------------------------|
|Programa  |RDDV004  |Autora |Thais Paiva         | Data |  25/06/2024       |
|----------------------------------------------------------------------------|
|Descricao | Validacao do Tipo de Requisicao                                 |						  
|----------------------------------------------------------------------------|
|Uso       |REDEDOR                                                          |						  
|----------------------------------------------------------------------------|
*/

User Function RDDV004(cTpSC,cTpReq)
Local aArea := FwGetArea()
Local lRet 	:= .t.
Local cMVXTPSCAP := ALLTRIM(GetMv("MV_XTPSCAP")) //Parametro que indica se O TIPO exige aprovacao de SC
Local cFSXTPSCCA := ALLTRIM(GetMv("FS_XTPSCCA")) //Parametro que indica se O TIPO exige aprovacao de SC
Local cMsgErro := ""

If IsInCallStack('U_REDA003')
	Return(lRet)
ENDIF

If  (cTpSC $ cMVXTPSCAP) .OR.  (cTpSC $ cFSXTPSCCA)
	Return(lRet)
EndIf

If Empty(Alltrim(cTpReq))
	cMsgErro := "Tipo de Requisicao nao pode estar em branco!"
	lRet := .F.
Else
	DbSelectArea("PZY")
	DbSetOrder(2)
	Dbgotop()
	If !(DbSeek(xFilial("PZY")+cTpReq+cTpSC))
		cMsgErro := "Nao e permitido utilizar tipo de requisicao que nao esteja amarrado ao tipo de solicitacao!"
		lRet := .F.
	Else
		lRet := .T.
	Endif
endif 

If !lRet .AND. !Empty(Alltrim(cMsgErro))
	If l110Auto
		aadd(_aMsgErr,cMsgErro)
	Else 
		Alert(cMsgErro)
	Endif 
EndIf

FwRestArea(aArea)
Return lRet
