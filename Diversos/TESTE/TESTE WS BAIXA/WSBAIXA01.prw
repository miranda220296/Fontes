#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"
#INCLUDE "FWMVCDEF.CH"

WSService WSBAIXA01 Description "Teste de Baixa"
    WSData Filial   as Filial
    WSData cRetorno             as String


    WSMethod UpBaixa   Description "Teste de baixa"

EndWSService 

WSMethod UpBaixa WSReceive Filial WSSend cRetorno WSService WSBAIXA01
    Begin WSMethod    
        ::cRetorno := U_FSBAIXA01(Filial)
    End WSMethod
Return .T.  



WSStruct Filial
    WSData cFILFab as String
EndWSStruct
 