// #########################################################################################
// Projeto: Rede D'Or
// Modulo : Financeiro
// Fonte  : F240PCB
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------
// 01/09/22 | Rafael Yera Barchi| Ponto de Entrada para valida��o do cancelamento do border�
// ---------+-------------------+-----------------------------------------------------------

#INCLUDE    "PROTHEUS.CH"


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} F240PCB
//Ponto de Entrada para valida��o do cancelamento do border�
@author Rafael Yera Barchi
@since 01/09/2022
@version 1.00
@type function

/*/
//------------------------------------------------------------------------------------------
User Function F240PCB()

    Local lRet      := .T.
    Local cBancoMNK := PadR(SuperGetMV("MK_BANCO"    , , ""), TamSX3("A6_COD")[1])


    If !IsBlind() .And. SE2->E2_PORTADO == cBancoMNK
        lRet := .F.
        FWAlertInfo("N�o � permitido cancelar o border� de t�tulos negociados no Portal Monkey", "Aviso")
    EndIf

Return lRet
