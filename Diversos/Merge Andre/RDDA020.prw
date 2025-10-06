#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COMMON.CH"

//////////////////////////////////////////////////////////////////////////////////////
//+--------------------------------------------------------------------------------+//
//| PROGRAMA  | RDDA020 | AUTORA| Thais Paiva              | DATA | 13/06/2024	   |//
//+--------------------------------------------------------------------------------+//
//| DESCRICAO  | Funcções utilizadas nos campos da PZY e SC1 - 20390232            |//
//+--------------------------------------------------------------------------------+//
//////////////////////////////////////////////////////////////////////////////////////

User function PesqTPSol(xTIPOSC)
Local nPosTpSol := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPSC"})
Local nPosDsSc  := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XDESCTP"})
Local nPosTpReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPREQ"}) 
Local nPosDsReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XDESRQ"})
Local _cTipReq  := ""
Local cMVXTPSCAP := ALLTRIM(GetMv("MV_XTPSCAP")) //Parametro que indica se O TIPO não exige aprovação de SC
Local cFSXTPSCCA := ALLTRIM(GetMv("FS_XTPSCCA")) //Parametro que indica se O TIPO não exige aprovação de SC
Local cSCCorp := ALLTRIM(SUPERGETMV("FS_TPSCCP",.F.,"")) 

_cTipSC := Alltrim(xTIPOSC)

If Empty(Alltrim(_cTipSC))
    _cTipSC:= M->C1_XTPSC
EndIf

If  (_cTipSC $ cMVXTPSCAP) .OR.  (_cTipSC $ cFSXTPSCCA)
    M->C1_XTPREQ        := "   "
    M->C1_XDESRQ        := space(80)
    Acols[n][nPosTpReq] := "   " 
    Acols[n][nPosDsReq] := space(80)
Else
	If _cTipSC $ cSCCorp
		M->C1_XTPREQ        := "   "
		M->C1_XDESRQ        := space(80)
		Acols[n][nPosTpReq] := "   " 
		Acols[n][nPosDsReq] := space(80)
	Else
		DbSelectArea("PZY")
		DbSetOrder(1)
		Dbgotop()
		If dbSeek(xFilial("PZY")+_cTipSC)
			If Empty(Alltrim(PZY->PZY_XTPREQ))
				If l110Auto 
					aadd(_aMsgErr,"O Tipo SC informado não possui Tipo de Requisição Cadastrado. Favor verificar.")
				Else
					Alert("O Tipo SC informado não possui Tipo de Requisição Cadastrado. Favor verificar.")
				endif
				M->C1_XTPSC			:= "  "
				M->C1_XDESCTP		:= space(80)
				M->C1_XTPREQ        := "   "
				M->C1_XDESRQ        := space(80)
				Acols[n][nPosTpSol] := "  "
				Acols[n][nPosDsSc]  := space(80)
				Acols[n][nPosTpReq] := "   "
				Acols[n][nPosDsReq] := space(80)
				
			Else
				_cTipReq := PZY->PZY_XTPREQ
				M->C1_XTPREQ        := PZY->PZY_XTPREQ
				M->C1_XDESRQ        := PZY->PZY_XDESRQ
				Acols[n][nPosTpReq] := PZY->PZY_XTPREQ
				Acols[n][nPosDsReq] := PZY->PZY_XDESRQ
			endif
		Else
			If l110Auto 
				aadd(_aMsgErr,"Tipo SC inválido")
			Else
				Alert("Tipo SC inválido")
			endif
			M->C1_XTPSC			:= "  "
			M->C1_XDESCTP		:= space(80)
			M->C1_XTPREQ        := "   "
			M->C1_XDESRQ        := space(80)
			Acols[n][nPosTpSol] := "  "
			Acols[n][nPosDsSc]  := space(80)
			Acols[n][nPosTpReq] := "   "
			Acols[n][nPosDsReq] := space(80)
		endif
	EndIf
	
Endif

Return _cTipReq

User Function PesqTpReq(xTipoReq) 
Local nPosTpReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPREQ" }) 
Local nPosTpSol := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPSC"})
Local nPosDsReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XDESRQ"})
Local _cDesRQ   := space(80)
Local _cTipSC   := "  " 

_cTipSC := Alltrim(Acols[n][nPosTpSol])
_cTipReq := xTipoReq

If Empty((Alltrim(_cTipSC)))
    _cTipSC:= M->C1_XTPSC
EndIf

If Empty(Alltrim(_cTipReq))
	_cTipReq := M->C1_XTPREQ
EndIf

DbSelectArea("PZY")
DbSetOrder(2)
DbGoTop()
If dbSeek(xFilial("PZY")+_cTipReq+_cTipSC)
    _cDesRQ:= PZY->PZY_XDESRQ
    M->C1_XDESRQ        := _cDesRQ
    Acols[n][nPosDsReq] := _cDesRQ
else
	M->C1_XTPREQ        := "   "
	M->C1_XDESRQ        := space(80)
	Acols[n][nPosTpReq] := "   " 
	Acols[n][nPosDsReq] := space(80)
	If l110Auto 
		aadd(_aMsgErr,"Tipo de Requisição inválido.")
	Else
		Alert("Tipo de Requisição inválido.")
	endif
EndIf
        
Return _cDesRQ


User Function _ValTpSol() 
Local nPosTpReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPREQ" }) 
Local nPosDsReq := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XDESRQ" }) 
Local nPosTpSol := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPSC"})
Local cMVXTPSCAP := ALLTRIM(GetMv("MV_XTPSCAP")) //Parametro que indica se O TIPO não exige aprovação de SC
Local cFSXTPSCCA := ALLTRIM(GetMv("FS_XTPSCCA")) //Parametro que indica se O TIPO não exige aprovação de SC
Local lRet       :=.T.
Local xTIPOSC    := Acols[n][nPosTpSol]
Local xTIPOREQ   := Acols[n][nPosTpReq]

_cTipSC := Alltrim(xTIPOSC)

If Empty((Alltrim(_cTipSC)))
    _cTipSC:= M->C1_XTPSC
EndIf

If Empty(Alltrim(xTIPOREQ))
	xTIPOREQ := M->C1_XTPREQ
EndIf

If !Empty(Alltrim(xTIPOREQ))
    If  (_cTipSC $ cMVXTPSCAP) .OR.  (_cTipSC $ cFSXTPSCCA)
        If l110Auto 
			aadd(_aMsgErr,"O TIPO SC escolhido não está configurado para aceitar tipo de requisição! Tipo escolhido não irá gerar alçada!")
		Else
			Alert("O TIPO SC escolhido não está configurado para aceitar tipo de requisição! Tipo escolhido não irá gerar alçada!")
		endif
        lRet := .F.
        M->C1_XDESRQ        := "   "
        M->C1_XDESRQ        := SPACE(80)
        aCols[n][nPosTpReq] := Space(3)
        aCols[n][nPosDsReq] := SPACE(80)
    endif
endif

Return(lRet)

/*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Date:           17/01/2023
Author:         Paulo Dias
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Function:       HabReq
Description:    rotina de bloqueio do campo Tp Requisição
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*/

User Function HabReq()
Local lOK        := .T.
Local nTipSC     := Ascan(aHeader,{|x|Alltrim(x[2])=="C1_XTPSC"})
Local cMVXTPSCAP := ALLTRIM(GetMv("MV_XTPSCAP")) //Parametro que indica se O TIPO não exige aprovação de SC
Local cFSXTPSCCA := ALLTRIM(GetMv("FS_XTPSCCA")) //Parametro que indica se O TIPO não exige aprovação de SC
Local cSCCorp := ALLTRIM(SUPERGETMV("FS_TPSCCP",.F.,""))
Local nUsado := Len(aHeader)

If nTipSC > 0 .AND. !aCols[n][nUsado + 1]
    If (Alltrim(aCols[n][nTipSC]) $ cMVXTPSCAP) .OR. (Alltrim(aCols[n][nTipSC]) $ cFSXTPSCCA) .OR. EMPTY(Alltrim(aCols[n][nTipSC]))
        lOK := .F.
    else
		If Alltrim(aCols[n][nTipSC]) $ cSCCorp
			lOK := .T.
		Else
			lOK := .F.
		endif
    Endif
Endif 

Return lOK

User Function  _CHVPZY(xTIPOSC,xGRAPRO,xTPREQ)
Local lRet  := .T.
Local cMVXTPSCAP := ALLTRIM(GetMv("MV_XTPSCAP")) //Parametro que indica se O TIPO exige aprovação de SC
Local cFSXTPSCCA := ALLTRIM(GetMv("FS_XTPSCCA")) //Parametro que indica se O TIPO exige aprovação de SC

_cTipSC := Alltrim(xTIPOSC)

If Empty((Alltrim(_cTipSC)))
    _cTipSC:= M->C1_XTPSC
EndIf

If Empty(Alltrim(xTPREQ))
	xTPREQ := M->C1_XTPREQ
EndIf

If  (_cTipSC $ cMVXTPSCAP) .OR.  (_cTipSC $ cFSXTPSCCA)
	Help("", 1, "RDDA002", ,"Este tipo de solicitação está configurado para não gerar aprovação! Favor utilizar outro tipo.", 1, 0, , , , , , {"Inclusão não permitida!"})
	lRet:=.F.
ENDIF
If lRet .AND. (INCLUI .OR. ALTERA)
	If !Empty(Alltrim(_cTipSC)) .AND. !Empty(Alltrim(xTPREQ))
		DbSelectArea("PZY")
		DbSetOrder(2)
		PZY->(Dbgotop())
		If dbSeek(xFilial("PZY")+xTPREQ+_cTipSC)
			Help("", 1, "RDDA002", ,"Já existe  um registro cadastrado com estes dados!!!", 1, 0, , , , , , {"Inclusão não permitida!"})
			lRet:=.F.
		Endif
	endif 
EndIf

Return lRet
