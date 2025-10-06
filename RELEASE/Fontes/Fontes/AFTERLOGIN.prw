#Include "Protheus.ch"
/*/{Protheus.doc} AfterLogin
Anstes de Logar para informar ao usu�rio que � uma filial Simplificada.
@type function
@version P12 
@author Ricardo junior
@since 1/10/2025
@return variant, Nulo
/*/ 
User Function AfterLogin()
    Local aArea := GetArea()
    if U_VALSIMP(cFilAnt)
        MsgInfo("Voc� est� acessando uma filial do P12 Simplificado!", "Aten��o")
    endif    
    RestArea(aArea)
Return
