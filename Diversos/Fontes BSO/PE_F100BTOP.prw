/*/{Protheus.doc} User Function F100BTOP
    Permite acrescentar bot�es na interface
    @type  Function
    @author Gianluca Moreira
    @since 22/08/2021
    /*/
User Function F100BTOP()

    Local aButton := ParamIXB[1]
    Local cCtbOn  := SuperGetMV('FS_C200040',, '')
Conout("Entrou ponto de entrada F100BTOP " + Time())

    //A doc. oficial da ExecAuto menciona o par�metro NCTBONLINE para controlar
    //se contabiliza online ou n�o. Ap�s an�lise da rotina padr�o, verificou-se
    //que o par�metro n�o � utilizado, e � necess�rio alterar o MV_PAR04 
    //manualmente neste ponto de entrada
    If FWIsInCallStack('U_F2000401') .And. !Empty(cCtbOn)
	    MV_PAR04 := Val(cCtbOn)
    EndIf
Conout("Saiu ponto de entrada F100BTOP " + Time())
Return aButton
