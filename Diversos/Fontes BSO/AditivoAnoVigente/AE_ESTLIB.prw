#INCLUDE "PROTHEUS.CH"

/*{Protheus.doc} AE_ESTLIB()
Fun��o para estornar a libera��o da solicita��o de viagem e excluir o t�tulo gerado
@Author			Ramon Teodoro e Silva
@Since			17/07/2024
@Version		P12.2210
@Project    	
@Return		Nil	 */

User Function AE_ESTLIB(nOpcEx)

Local lRet  := .t.
Local aArea := GetArea() 

If nOpcEx == 1
  
      If Empty(LHP->LHP_DOCUME)

        MsgAlert("N�o existe t�tulo a pagar para essa movimenta��o.", "Op��o inv�lida!")
        lRet := .F.

    Else
      
        If MsgYesNo("Deseja estornar o adiantamento desta solicita��o de viagem? Essa a��o ir� excluir o PA gerado no financeiro.", "Aten��o!")    
      
            DbSelectArea("LHQ")
            DbSetOrder(1)

            If LHQ->(DbSeek(LHP->(LHP_FILIAL+LHP_CODIGO)))
                If LHP->LHP_XESTIT <> 'S'
                    U_AE_DVEXC()
                Else
                    MsgAlert("Estorno j� realizado", "Op��o inv�lida!")
                    lRet := .F.
                EndIf
            Else
                MsgAlert("Adiantamento n�o encontrado.")
                lRet := .F.
            EndIf
        
        EndIf

    EndIf
Else

    DbSelectArea("LHP")
    DbSetOrder(1)
    If LHP->(DbSeek(LHQ->(LHQ_FILIAL+LHQ_CODIGO)))

        If LHP->LHP_XESTIT <> "S" 
            If Empty(LHP->LHP_DOCUME)
                MsgAlert("N�o existe t�tulo a pagar para essa movimenta��o.", "Op��o inv�lida!")
                 lRet := .F.
            Else
                If MsgYesNo("Deseja estornar a libera��o desta presta��o de contas? Essa a��o ir� excluir o t�tulo gerado no financeiro.", "Aten��o!")    
                    U_AE_DVEXC()
                EndIf
            EndIf
        Else
            MsgAlert("Estorno j� realizado", "Op��o inv�lida!")
            lRet := .F.
        EndIf
    
    EndIf
    
EndIf

RestArea(aArea)
Return lRet
