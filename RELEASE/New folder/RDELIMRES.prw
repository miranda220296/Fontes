#Include "Protheus.ch"
#Include "rwmake.ch"
#include "totvs.ch"

#DEFINE CRLF Chr(13)+Chr(10)

//------------------------------------------------------------------------------
/*/{Protheus.doc} RDELIMRES

Fun��o respons�vel pela realiza��o da Elimina��o dos Res�duos dos Pedidos de Compras do per�odo de 2016 � 2021.
 
@type function
@version  
@author Sato
@since 16/06/2025
@return array, return_description
/*/ 
//------------------------------------------------------------------------------
User Function RDELIMRES() As Array

Local oWizard       As Object
Local oStep1        As Object
Local oStep2        As Object
Local oStep3        As Object
Local oStep4        As Object
Local oStep5        As Object

Local lCancel		As Logical
Local cArquivo      As Character
Local cObsRes       As Character
Local lIntegra      As Logical
Local aDadosSC7     As Array
Local aCampos       As Array
Local aLogs         As Array
Local aArea         As Array

Local cFilBkp       As Character

lCancel		:= .F.
cArquivo    := ""
cObsRes     := ""
lIntegra    := .T.
aDadosSC7   := {}
aCampos     := {}
aLogs       := {}

aArea       := FwGetArea()

cFilBkp     := cFilAnt

oWizard := FWWizardControl():New( /*oObjPai*/, { 560, 850 } )	// Instancia a classe FWWizardControl

oWizard:ActiveUISteps()

/*
    Apresenta��o
*/
oStep1 := oWizard:AddStep( 'Step1', { | oPanel | Step1( oPanel ) } )
oStep1:SetStepDescription( "In�cio" )            		        // Define o t�tulo do "Passo" | "In�cio"
oStep1:SetNextTitle( "Pr�ximo" )	    				        // Define o t�tulo do bot�o de avan�o | "Pr�ximo"
oStep1:SetNextAction( { || .T. } )						        // Define o bloco ao clicar no bot�o Pr�ximo
oStep1:SetCancelAction( { || lCancel := .T. } )			        // Define o bloco ao clicar no bot�o Cancelar

/*
    "Sele��o de Arquivo"
*/
oStep2 := oWizard:AddStep( 'Step2', { | oPanel | Step2( oPanel, @cArquivo, @cObsRes, @lIntegra ) } )
oStep2:SetStepDescription( "Sele��o de Arquivo" )      	        // Define o t�tulo do "Passo" | "Sele��o de Arquivo"
oStep2:SetNextTitle( "Pr�ximo" )						        // Define o t�tulo do bot�o de avan�o | "Pr�ximo"
oStep2:SetNextAction( { || ValStep2( cArquivo, cObsRes ) } )	// Define o bloco ao clicar no bot�o Pr�ximo
oStep2:SetCancelAction( { || lCancel := .T. } )			        // Define o bloco ao clicar no bot�o Cancelar

/*
    "Confer�ncia dos Dados"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
*/
oStep3 := oWizard:AddStep( 'Step3', { | oPanel | Step3( oPanel, cArquivo, cObsRes, lIntegra, @aDadosSC7, @aCampos ) } )
oStep3:SetStepDescription( "Confer�ncia dos Dados" )            // Define o t�tulo do "Passo" | "Confer�ncia dos Dados"
oStep3:SetNextTitle( "Pr�ximo" )								// Define o t�tulo do bot�o de avan�o | "Pr�ximo"
oStep3:SetNextAction( { || ValStep3( aDadosSC7, aCampos ) } )   // Define o bloco ao clicar no bot�o Pr�ximo
oStep3:SetCancelAction( { || lCancel := .T. } )					// Define o bloco ao clicar no bot�o Cancelar

/*
    "Processamento das corre��es"
*/
oStep4 := oWizard:AddStep( 'Step4', { | oPanel | Step4( oPanel, cArquivo, cObsRes, lIntegra, aDadosSC7, aCampos, @aLogs ) } )
oStep4:SetStepDescription( "Processamento dos Pedidos" )        // Define o t�tulo do "Passo" | "Processamento das corre��es"
oStep4:SetNextTitle( "Pr�ximo" )                                // Define o t�tulo do bot�o de avan�o | "Pr�ximo"
oStep4:SetNextAction( { || ValStep4( aLogs ) } )                // Define o bloco ao clicar no bot�o Pr�ximo
oStep4:SetCancelAction( { || lCancel := .T. } )                 // Define o bloco ao clicar no bot�o Cancelar

/*
    "Finaliza��o"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
*/
oStep5 := oWizard:AddStep( 'Step5', { | oPanel | Step5( oPanel, cArquivo, aLogs) } )
oStep5:SetStepDescription( "Finaliza��o" )                      // Define o t�tulo do "Passo" | "Finaliza��o"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
oStep5:SetNextAction( { || .T. } )	                            // Define o bloco ao clicar no bot�o Pr�ximo
oStep5:SetCancelAction( { || lCancel := .F. } )					// Define o bloco ao clicar no bot�o Cancelar

oWizard:Activate()

oWizard:Destroy()

cFilAnt := cFilBkp

FwRestArea(aArea)

Return



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step1

Fun��o respons�vel pela exibi��o da Tela de apresenta��o

@type function
@version  
@author Sato
@since 16/06/2025
@param oPanel, object, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step1( oPanel As Object )

Local oFont		As Object
Local oFontV	As Object
Local oSayTop	As Object
Local oSay1     As Object
Local oSay2     As Object

oFont 	:= TFont():New( ,, -20, .T., .T.,,,,, )
oFontV 	:= TFont():New( ,, -12, .T., .T.,,,,, )

oSayTop	:= TSay():New( 010,  10, { || "Elimina��o de Residuo" }, oPanel,, oFont,,,, .T., CLR_BLUE, )
oSay1	:= TSay():New( 030,  10, { || "Este programa tem como obejtivo realizar manualmente a Elimina��o de Res�duo dos Pedidos de Compras." }, oPanel,,,,,, .T., CLR_BLUE, )

oSay1	:= TSay():New( 040,  10, { || "Para a realiza��o da Elimina��o de Res�duo dos Pedidos de Compras, � necess�rio a cria��o de um template no formato CSV com os seguintes campos:" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay1	:= TSay():New( 050,  15, { || "- C7_FILIAL - Filial do Sistema;" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay1	:= TSay():New( 060,  15, { || "- C7_NUM - N�mero do Pedido;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 070,  15, { || "- C7_LOJA - Loja do fornecedor;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 080,  15, { || "- C7_COND - C�digo da Condi��o de Pagto;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 090,  15, { || "- C7_FILENT - Filial para Entrega;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 100,  15, { || "- C7_OBS - Observa��es;" }, oPanel,,,,,, .T., CLR_BLUE, )

//oSay1	:= TSay():New( 050, 145, { || "- C7_ITEM - Item do pedido de compra;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 060, 145, { || "- C7_PRODUTO  - C�digo do produto;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 070, 145, { || "- C7_QUANT - Quantidade do Item;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 080, 145, { || "- C7_PRECO - Pre�o do Item;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 090, 145, { || "- C7_TPFRETE - Tipo Frete;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 100, 145, { || "- C7_FRETE - Valor Frete;" }, oPanel,,,,,, .T., CLR_BLUE, )

//oSay1	:= TSay():New( 050, 275, { || "- C7_LOCAL - Local de Estoque;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 060, 275, { || "- C7_CC - Centro de Custo;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 070, 275, { || "- C7_XFRONT - Sigla do Fronte;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 080, 275, { || "- C7_XNUM - ID do Pedido de Compra no Fronte." }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 090, 275, { || "- C7_DESC1 - Desconto;" }, oPanel,,,,,, .T., CLR_BLUE, )
//oSay1	:= TSay():New( 100, 275, { || "- C7_XDESFIN - Desc. Financeiro;" }, oPanel,,,,,, .T., CLR_BLUE, )

oSay2	:= TSay():New( 115, 10, { || "Importante: " }, oPanel,, oFontV,,,, .T., CLR_BLUE, )
oSay2	:= TSay():New( 125, 10, { || "Os dados do arquivo CSV (template) utilizados como base dos uploads, dever�o seguir algumas premissas:" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay2	:= TSay():New( 135, 15, { || "- Utilizar ponto e v�rgula (;) como separador de colunas;" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay2	:= TSay():New( 145, 15, { || "- Utilizar v�rgula (,) como separador da parte decimal em campos num�ricos;" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay2	:= TSay():New( 155, 15, { || "- Utilizar 4 d�gitos para especificar o ano em campos tipo 'data'. Ex.: dd/mm/aaaa;" }, oPanel,,,,,, .T., CLR_BLUE, )
oSay2	:= TSay():New( 165, 15, { || "- N�o conter caracteres especiais;" }, oPanel,,,,,, .T., CLR_BLUE, )

Return



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step2

Fun��o respons�vel pela Sele��o do Arquivo de Upload de Elimina��o de Res�duo dos Pedidos de Comrpas.

@type function
@version  
@author Sato
@since 02/07/2025
@param oPanel, object, param_description
@param cArquivo, character, param_description
@param cObsRes, character, param_description
@param lIntegra, logical, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step2( oPanel As Object, cArquivo As Character, cObsRes As Character, lIntegra As Logical)

Local aArea2    As Array
Local oButton   As Object
Local oGet1     As Object
Local oSay2     As Object
Local oGet2     As Object
Local oSay3     As Object
Local oCombo    As Object
Local nAltGet   As Numeric
Local aItens    As Array
Local cCombo    As Character

Default cArquivo := ''

aArea2 := FWGetArea()

cObsRes := space(250)
nAltGet := 13
aItens  := {'1 - Sim','2 - N�o'}
cCombo  := ""

oButton := TButton():New( 70, 10 , "Selecione arquivo...",oPanel,{ || cArquivo := cGetFile("Arquivos .CSV|*.CSV","Selecione o arquivo a ser importado",0,,.F.,GETF_LOCALHARD+GETF_NETWORKDRIVE) }, 60, nAltGet + 2 ,,,.F.,.T.,.F.,,.F.,,,.F. )
oGet1   := TGet():New( 70, 75, { |u| If( PCount() > 0, cArquivo := u, cArquivo ) }, oPanel, 280, nAltGet,,,,,,,,.T.,,,{|| .F.},,,,,,,"cArquivo" )

oSay2 := TSay():New( 100, 10, {||'Observa��o : '},oPanel,,,,,,.T.,,,50,20)
oGet2 := TGet():New(  97, 55, { |u| If( PCount() > 0, cObsRes := u, cObsRes ) }, oPanel, 320, 010, "@!",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cObsRes",,,,.F. )

oSay3 := TSay():New( 125, 10, {||'Deseja integrar Pedidos : '},oPanel,,,,,,.T.,,,70,20)
cCombo:= aItens[1]
oCombo := TComboBox():New( 122, 75,{|u|if(PCount()>0,cCombo:=u,cCombo)},aItens,40,15,oPanel,,{||IIF(Left(cCombo, 1) == "1", lIntegra := .T., lIntegra := .F. )},,,,.T.,,,,,,,,,'cCombo')

FWRestArea(aArea2)

Return



//------------------------------------------------------------------------------
/*/{Protheus.doc} ValStep2

Fun��o respons�vel pela verifica��o se foi selecionado um arquivo (CSV) e se foi adicionada uma Observa��o.

@type function
@version  
@author Sato
@since 02/07/2025
@param cArquivo, character, param_description
@param cObsRes, character, param_description
@return logical, return_description
/*/
//------------------------------------------------------------------------------
Static Function ValStep2(cArquivo As Character, cObsRes As Character) As Logical

Local lRet As Logical

lRet := .T.

If Empty(cArquivo)
    lRet := .F.
    Help(' ',1,'Preenchimento' ,,'Selecione um Arquivo para poder prosseguir.',2,0,)
EndIf

If Empty(cObsRes)
    lRet := .F.
    Help(' ',1,'Preenchimento' ,,'Informe o motivo da Elimina��o de res�duo para poder prosseguir.',2,0,)
EndIf

Return lRet



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step3

Fun��o que monta a tela de confer�ncia dos Pedidos de Compras a serem Eliminados Res�duo.

@type function
@version  
@author Sato
@since 02/07/2025
@param oPanel, object, param_description
@param cArquivo, character, param_description
@param cObsRes, character, param_description
@param lIntegra, logical, param_description
@param aDadosSC7, array, param_description
@param aCampos, array, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step3( oPanel As Object, cArquivo As Character, cObsRes As Character, lIntegra As Logical, aDadosSC7 As Array, aCampos As Array )

local oOK    As object
local oNO    As object
local oBrw   As object

Local aArea3 As Array

Default cArquivo    := ""
Default cObsRes     := ""
Default aDadosSC7   := {}
Default aCampos     := {}

aArea3 := FWGetArea()

oOK := LoadBitmap(GetResources(), "br_verde")
oNO := LoadBitmap(GetResources(), "br_vermelho")

FWMsgRun(oPanel, {|oSay| Step3Proc(oSay, cArquivo, @aDadosSC7, aCampos) }, "Processando", "Gerando dados para confer�ncia...")

oBrw  := TWBrowse():New( 000 , 000 , (oPanel:nClientWidth/2) , (oPanel:nClientHeight/2),,,,oPanel,,,,,,,,,,,,.F.,,.T.,,.F.,,, )
oBrw:SetArray(aDadosSC7)

////////////// TCColumn():New( < cTitulo >           , < bData >                              , [ cPicture ], [ uParam4 ], [ uParam5 ], [ cAlinhamento ], [ nLargura ], [ lBitmap ], [ lEdit ], [ uParam10 ], [ bValid ], [ uParam12 ], [ uParam13 ], [ uParam14 ] )

oBrw:AddColumn(TcColumn():New( ""                    , {||If(aDadosSC7[oBrw:nAt][01],oOK,oNO)},,,, "CENTER", 20, .T., .F.,,,, .F., ) )                   // Status
oBrw:AddColumn(TCColumn():New( RetTitle(aCampos[02]) , {|| aDadosSC7[oBrw:nAt][02] },,,,'LEFT' ,GetSx3Cache(aCampos[02],"X3_TAMANHO"),.F.,.F.,,,,.F.,))  // C7_FILIAL
oBrw:AddColumn(TCColumn():New( RetTitle(aCampos[03]) , {|| aDadosSC7[oBrw:nAt][03] },,,,'LEFT' ,GetSx3Cache(aCampos[03],"X3_TAMANHO"),.F.,.F.,,,,.F.,))  // C7_NUM
oBrw:AddColumn(TCColumn():New( "Descri��o do Erro"   , {|| aDadosSC7[oBrw:nAt][04] },,,,'LEFT' ,150,.F.,.F.,,,,.F.,))                                    // DESCRICAO DO ERRO

FWRestArea(aArea3)

Return



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step3Proc

Rotina respons�vel por realizar a leitura do arquivo CSV

@type function
@version  
@author Sato
@since 02/07/2025
@param oSay, object, param_description
@param cArquivo, character, param_description
@param aDadosSC7, array, param_description
@param aCampos, array, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step3Proc(oSay As Object, cArquivo As Character, aDadosSC7 As Array, aCampos As Array )

Local cBuffer   as Character
Local aLinha    as Array
Local nContLin  as Numeric

cBuffer     := ""
aLinha      := {}
nContLin    := 0

FT_FUSE(cArquivo)  
FT_FGOTOP() 

While !FT_FEOF()  
    
    // Capturar dados
    cBuffer := FT_FREADLN() //LENDO LINHA
    nContLin++
    //aLinha := Separa( Upper(cBuffer), ";")
    aLinha := Separa( Upper(";"+cBuffer)+";", ";")
    
    If nContLin > 1
        If Len(aCampos) = 0
            aLinha[1]  := "STATUS"
            aLinha[LEN(aLinha)] := "ERRO"
            aCampos := aClone(aLinha)
        Else
            aLinha[1] := .T.
            AADD( aDadosSC7, aLinha )
        EndIf
    EndIf

    FT_FSKIP()   

Enddo

FT_FUSE() 

Return .t.



//------------------------------------------------------------------------------
/*/{Protheus.doc} ValStep3

Fun��o que verifica se os arrays de  Campos e de Dados est�o v�zios.

@type function
@version  
@author Sato
@since 02/07/2025
@param aDadosSC7, array, param_description
@param aCampos, array, param_description
@return logical, return_description
/*/
//------------------------------------------------------------------------------
Static Function ValStep3( aDadosSC7 As Array, aCampos As Array ) As Logical

Local lRet  As Logical

lRet := .T.

If Len(aDadosSC7) = 0
    lRet := .F.
    Help(' ',1,'Inv�lido' ,,'Arquivo de dados inv�lido.',2,0,)
EndIf

If Len(aCampos) = 0
    lRet := .F.
    Help(' ',1,'Inv�lido' ,,'Arquivo de dados inv�lido.',2,0,)
EndIf

Return lRet



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step4

Fun��o que realiza a chamada da fun��o de Elimina��o de Res�duo dos Pedidos de Compra.

@type function
@version  
@author Sato
@since 02/07/2025
@param oPanel, object, param_description
@param cArquivo, character, param_description
@param cObsRes, character, param_description
@param lIntegra, logical, param_description
@param aDadosSC7, array, param_description
@param aCampos, array, param_description
@param aLogs, array, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step4( oPanel As Object, cArquivo As Character, cObsRes As Character, lIntegra As Logical, aDadosSC7 As Array, aCampos As Array, aLogs As Array )

Default cArquivo  := ""
Default cObsRes   := ""
Default aDadosSC7 := {}
Default aCampos   := {}
Default aLogs     := {}

FWMsgRun(oPanel, {|oSay| Step4Proc(oSay, cArquivo, cObsRes, lIntegra, aDadosSC7, aCampos, @aLogs) }, "Processando", "Processando os Pedidos de Compras...")

FWAlertSuccess("Finalizado o processo de Leitura e Upload de Pedido de Compras", "Upload de Pedido de Compras")

Return


//------------------------------------------------------------------------------
/*/{Protheus.doc} Step4Proc

Fun��o que executa a Elimina��o de Res�duo dos Pedidos de Compra e integrando com o Front.

@type function
@version  
@author Sato
@since 02/07/2025
@param oSay, object, param_description
@param cArquivo, character, param_description
@param cObsRes, character, param_description
@param lIntegra, logical, param_description
@param aDadosSC7, array, param_description
@param aCampos, array, param_description
@param aLogs, array, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function Step4Proc(oSay As Object, cArquivo As Character, cObsRes As Character, lIntegra As Logical, aDadosSC7 As Array, aCampos As Array, aLogs As Array)

Local nX       := 1

Local cFilPed  := ""
Local cNumPed  := ""
Local lEimina  := .F.

Default cArquivo  := ""
Default cObsRes   := ""
Default aDadosSC7 := {}
Default aCampos   := {}
Default aLogs     := {}

AADD(aLogs, "FILIAL;NUMERO;STATUS" )

For nX := 1 To len(aDadosSC7)
    
    cFilPed := aDadosSC7[nX,2]
    cNumPed := aDadosSC7[nX,3]
    
    dbSelectArea("SC7")
    SC7->( dbSetOrder(1) )           //1 - C7_FILIAL+C7_NUM+C7_ITEM_C7_SEQUEN   // 3 - C7_FILIAL+C7_FORNECE_C7_LOJA+C7_NUM
    SC7->( dbGoTop() )
    IF SC7->( dbSeek(cFilPed+cNumPed) )
        Do While SC7->C7_FILIAL == cFilPed .and. SC7->C7_NUM == cNumPed
            If SC7->C7_ENCER == ' '
                SC7->( RecLock("SC7",.F.) )
                    // ATUALIANDO OS CAMPOS DE DA ELIMINACAO DE RESIDUO
                    SC7->C7_XOBSRES := cObsRes
                    SC7->C7_XDATRES := DATE()
                    SC7->C7_RESIDUO := "S"
                    SC7->C7_ENCER   := "E"

                SC7->( MsUnlock() )
                lEimina := .T.
            EndIf
            SC7->( dbSkip() )
        End
        If lIntegra
            If lEimina
                // Fun��o respons�vel pelo envio do Pedido para o Barramento
                cFilAnt := cFilPed

                u_F07022RE(cNumPed, 'R')

                AADD(aLogs, cFilPed+";"+cNumPed+";Pedido Eliminado Residuo no Protheus e enviado para o Barramento para ser enviado para o Front." )
                lEimina := .F.
            Else
                AADD(aLogs, cFilPed+";"+cNumPed+";Pedido sem Itens a serem Eliminado Residuos." )
            EndIf
        Else
            If lEimina
                AADD(aLogs, cFilPed+";"+cNumPed+";Pedido Eliminado Residuo no Protheus." )
                lEimina := .F.
            Else
                AADD(aLogs, cFilPed+";"+cNumPed+";Pedido sem Itens a serem Eliminado Residuos." )
            EndIf
        EndIf
    Else
        AADD(aLogs, cFilPed+";"+cNumPed+";Pedido nao encontrado." )
    EndIf
Next nX

Return .t.



//------------------------------------------------------------------------------
/*/{Protheus.doc} ValStep4

Fun��o que verifica se o arquivo de LOG esta vazio

@type function
@version  
@author Sato
@since 02/07/2025
@param aLogs, array, param_description
@return logical, return_description
/*/
//------------------------------------------------------------------------------
Static Function ValStep4( aLogs As Array ) As Logical

Local lRet  As Logical

lRet := .T.

If Len(aLogs) = 0
    lRet := .F.
    Help(' ',1,'Inv�lido' ,,'Arquivo de Log inv�lido.',2,0,)
EndIf

Return lRet



//------------------------------------------------------------------------------
/*/{Protheus.doc} Step5

Fun��o que apresenta a tela definaliza��o do processamento

@type function
@version  
@author Sato
@since 02/07/2025
@param oPanel, variant, param_description
@param cArquivo, character, param_description
@param aLogs, array, param_description
@return variant, return_description
/*/
Static Function Step5( oPanel As Objecto, cArquivo As Character, aLogs As Array )

Default aLogs     := {}
Default cArquivo  := ""

FWMsgRun(oPanel, {|oSay| GeraCSV(oSay, aLogs, cArquivo) }, "Processando", "Gerando arquivo de Logs...")

oFont:= TFont():New(,,-25,.T.,.T.,,,,,)

oSayTop := TSay():New(10,15,{|| "Finalizado o processo de Elimina��o de Res�duo."},oPanel,,oFont,,,,.T.,CLR_BLUE,)
oSayBottom1 := TSay():New(35,10,{|| "Consulte o arquivo de log no mesmo diret�rio onde esta o arquivo do Upload."},oPanel,,,,,,.T.,CLR_BLUE,)

Return



//------------------------------------------------------------------------------
/*/{Protheus.doc} GeraCSV

Fun��o respons�vel por gerar o arquivo de Log

@type function
@version  
@author Sato
@since 02/07/2025
@param oSay, object, param_description
@param aLogs, array, param_description
@param cArquivo, character, param_description
@return variant, return_description
/*/
//------------------------------------------------------------------------------
Static Function GeraCSV(oSay As Object, aLogs As Array, cArquivo As Character)

Local nFile
Local cDrive
Local cDir
Local cNome
Local cExt

Local cArq
Local cPath
Local nX

SplitPath( cArquivo, cDrive, cDir, cNome, cExt )

If!ApOleClient("MSExcel")
	MsgAlert("Microsoft Excel n�o iNTSalado!")
	Return
EndIf

cArq  := cNome+"_LOG"+cExt

cPath := cDrive+cDir

nFile  := FCreate(cPath+cArq)

If nFile==-1
	MsgAlert("Nao conseguiu criar o arquivo!")
	Return
EndIf

For nX:=1 TO LEN(aLogs)
	FWrite(nFile,aLogs[nX]+Chr(13)+Chr(10))
Next nX

FClose(nFile)

shellExecute("Open", cPath,"Null" , "C:\", 1 )

Return
