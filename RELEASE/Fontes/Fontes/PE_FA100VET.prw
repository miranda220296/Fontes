#Include 'TOTVS.ch'

/*/{Protheus.doc} User Function FA100VET
    Valida estorno de transfer�ncia entre contas
    @type  Function
    @author Gianluca Moreira
    @since 31/05/2021
    /*/
User Function FA100VET()

    Local nRecOrig := ParamIXB[1]
    Local nRecDest := ParamIXB[2]
    Local lRet     := .T.
    Local lGrpHblt  := .F. //Verifica tabela PX1 para a empresa/filial atual
    Conout("Entrou ponto de entrada FA100VET " + Time())
    lGrpHblt := U_F2000132()
    //Verifica se est� habilitada a integra��o neste grupo de empresas
    If lGrpHblt
        lRet := U_F2000411(nRecOrig, nRecDest) //Valida se a transfer�ncia veio do XRT
    EndIf    
    Conout("Saiu ponto de entrada FA100VET " + Time())
Return lRet
