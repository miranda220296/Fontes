/*
//=============================================================================================\\
// Programa   E-Mail   | Autor  Diego Fraidemberge Mariano                | Data    28/08/24   ||
//=============================================================================================||
//Desc.     | Classe para envio de email. Busca dados nos par�metros os m�todos sempre retornam||
//          | .t. ou .f., e a MSG de erro esta armazenada no elemento cError.                  ||
//          | Use o m�todo ExibeErro ou usar o elemento diretamente.                           ||
//=============================================================================================//
*/
#Include "Protheus.ch"   //  padr�o
#include "ap5mail.ch"    // defini��es para emails

*=====================================================================================================================================*
user Function EmailClass()	//--- Fun��o existente somente para aparecer este programa no INSPETOR DE OBJETOS,
							//		e para testar se este programa est� compilado no reposit�rio...
*=====================================================================================================================================*
Return .T.

*=====================================================================================================================================*
Class EMail	// Classe para envio de email
*=====================================================================================================================================*
	Data cSMTPServer										// nome do servidor	
	Data cMailConta											// remetente
	Data cMailFrom                                          // remetente do email
	Data cMailSenha											// senha do remetente
	Data lAutentica											// Determina se o Servidor de Email necessita de Autentica��o
	Data cUserAut											// Usu�rio para Autentica��o no Servidor de Email
	Data cPassAut											// Senha para Autentica��o no Servidor de Email
	Data aEmail												// array com os destinos
	Data aEmailCC											// array com os destinos
	Data aEmailCCo											// array com os destinos
	Data cAssunto											// assunto
	Data cMensagem											// corpo da msg ; pode ser um html
	Data aAnexos											// arquivos anexados
	Data cAnexo
	Data cError												// recupera a msg de erro
	Data lExibeErro											// .F. n�o exibe mensagem de erro/alerta, .T. Exibe o erro em TELA (normal) ou no CONSOLE.LOG (Background)
	Data lError												// .F. para sucesso e .T. para problemas
    Data cErrorMet											// Nome do m�todo onde ocorreu o erro
   
	Method New() Constructor								// M�todo contrutor que inicializa o objeto
	Method Destino(cEMail)									// define os endere�os de destino
	Method DestCC(cEMail)									// define os endere�os de destino
	Method DestCCo(cEMail)									// define os endere�os de destino
	Method Assunto(cTexto)									// Define o assunto
	Method Mensagem(cTexto,lAdd)							// Define o corpo da Mensagem. Pode ser um HTML. (cTexto=Mensagem, lAdd=.T. para ADICIONAR � MENSAGEM EXISTENTE, lAdd=.F. PARA INICIALIZAR A MENSAGEM)
	Method Anexo(cAnexo)				                    // Carrega anexos ao email
	Method MandaMail()										// Envia o email registrado
    Method Parametros()										// Configura os par�metros no SX6 
    Method SetError(cTexto,lErro,cMetodo,lExibeMsg)	        // Marca a ocorrencia de erro no objeto
   															//		cTexto=Mensagem de Erro/Alerta
   															//		lErro=.T. Houve erro //	lErro=.F. N�o houve erro
   															//		cMetodo=Nome do M�todo da Classe E-Mail onde ocorreu a mensagem
   															//		lExibeMsg=.T.	Exibe a mensagem de erro	//	lExibeMsg=.F.	N�o exibe a mensagem de erro
    Method ExibeErro()										// Exibe a mensagem de erro
	Method SetGetShowErr(cOnOff)							// liga ("ON") ou desliga ("OFF") a exibi��o das mensagens de erro do objeto E-mail; Sem par�metros retorna o estado atual
EndClass

*=====================================================================================================================================*
Method New() class EMail                           // Inicializa a classe com valores b�sicos
*=====================================================================================================================================*
	Self:cSMTPServer:= AllTrim(GetMv("MV_RELSERV"))				// nome do servidor
	Self:cMailconta := AllTrim(GetMv("MV_RELACNT"))	
	Self:cMailfrom  := AllTrim(GetMv("MV_RELFROM"))  			// remetente
	Self:cMailsenha := AllTrim(GetMv("MV_RELPSW"))				// senha do remetente
	Self:lAutentica := GetMv("MV_RELAUTH",,.F.)					// Determina se o Servidor de Email necessita de Autentica��o
	Self:cUserAut   := Alltrim(GetMv("MV_RELAUSR",," "))		// Usu�rio para Autentica��o no Servidor de Email
	Self:cPassAut   := Alltrim(GetMv("MV_RELAPSW",," "))		// Senha para Autentica��o no Servidor de Email
	Self:lExibeErro := .T.										// Flag que define se as mensagens de erro do objeto de e-mail ser�o exibidas (TELA/BACKGROUND)
	Self:aEmail     := {}										// array com os destinos
	Self:aEmailCC   := {}										// array com os destinos
	Self:aEmailCCo  := {}										// array com os destinos
	Self:cAssunto   := ""										// assunto
	Self:cMensagem  := ""										// corpo da msg ; pode ser um html
	Self:aAnexos    := {}										// arquivos anexados
	Self:SetError("Objeto Email inicializado",.F.,"NEW")		// recupera a msg de erro
return Self

*=====================================================================================================================================*
Method Destino(cEMail) class EMail	// M�todo que monta os destinat�rios do email
*=====================================================================================================================================*
	aAdd(Self:aEmail,If(Empty(cEMail),"",cEMail))
	If	Empty(cEMail)
		Self:SetError("Endere�o de E-mail Destino n�o definido corretamente",.T.,"Destino")
	EndIf
return Self:lError

*=====================================================================================================================================*
Method DestCC(cEMail) class EMail	// M�todo que monta os destinat�rios do email
*=====================================================================================================================================*
	aAdd(Self:aEmailCC,If(Empty(cEMail),"",cEMail))
	If	Empty(cEMail)
		Self:SetError("Endere�o de E-mail Destino CC n�o definido corretamente",.T.,"Destino")
	EndIf
return Self:lError

*=====================================================================================================================================*
Method DestCCo(cEMail) class EMail	// M�todo que monta os destinat�rios do email
*=====================================================================================================================================*
	aAdd(Self:aEmailCCo,If(Empty(cEMail),"",cEMail))
	If	Empty(cEMail)
		Self:SetError("Endere�o de E-mail Destino CCo n�o definido corretamente",.T.,"Destino")
	EndIf
return Self:lError

*=====================================================================================================================================*
Method Assunto(cTexto) class EMail 		// M�todo que define o assunto do email
*=====================================================================================================================================*
	Self:cAssunto	:=	cTexto
	If	Empty(Self:cAssunto)
		Self:SetError("Assunto do E-mail n�o definido corretamente",.T.,"Assunto")
	EndIf
return Self:lError 

*=====================================================================================================================================*
//user method Anexo(cAnexo) class u_E_mail //| M�todo que carrega os anexos do email |		
Method Anexo(cAnexo) class EMail //| M�todo que carrega os anexos do email |
*=====================================================================================================================================*
    If	Empty(cAnexo)
		Self:SetError("Anexo do E-mail n�o definido corretamente",.T.,"Anexo")
	Else
		aadd(self:aAnexos,cAnexo)
	EndIf
return self:lError

	
*=====================================================================================================================================*
Method Mensagem(cTexto,lAdd) class EMail			// M�todo que monta o corpo do email
*=====================================================================================================================================*
	Default lAdd:=.F.
//	Try
		If lAdd
			Self:cMensagem	+=	cTexto
		Else
			Self:cMensagem	:=	cTexto
		EndIf
//	Catch oErroTry
//		Self:SetError("Erro na atribui��o do corpo do E-mail (campo 'Mensagem'): "+oErroTry:Description+ENTER+oErroTry:ErrorStack,.T.,"Mensagem")
//	EndTry
return Self:lError

*=====================================================================================================================================*
Method MandaMail() class EMail	// M�todo que efetivamente envia o e-mail
*=====================================================================================================================================*
Local cError

Self:lError := .F. 

If !Empty(Self:cSMTPServer) .And. !Empty(Self:cMailConta) .And. !Empty(Self:cMailSenha)							// Existe uma conta configurada
	If	!Empty(Self:cMensagem)																					// existe mensagem
		If Len(Self:aEmail)	>	0												 								// existe destinat�rio
			If MailSmtpOn(Self:cSMTPServer,Self:cMailConta,Self:cMailSenha)										// Efetiva a conex�o
				If Self:lAutentica																				// precisa autentica��o
					If !MailAuth(Self:cUserAut,Self:cPassAut)													// tenta autenticar
						GET MAIL ERROR cError																	// verifica erro no autentica��o
						Self:SetError(cError,.T.,"MandaMail - MailAuth")													// marca que houve erro
					EndIf
				EndIf
				If !Self:lError																					// n�o houve erro
					//If !MailSend(Self:cMailConta,Self:aEmail,{},{},Self:cAssunto,Self:cMensagem,Self:aAnexos)	// n�o conseguiu enviar
					If !MailSend(Self:cMailFrom,Self:aEmail,Self:aEmailCC,Self:aEmailCCo,Self:cAssunto,Self:cMensagem,Self:aAnexos)
						GET MAIL ERROR cError																	// verifica erro no envio
						Self:SetError(cError,.T.,"MandaMail - MailSEnd")
						Self:lError := .T.													// marca que houve erro
					Else
						Self:lError := .F. 
					EndIf
				EndIf
				MailSmtpOff()
			Else
				GET MAIL ERROR cError		  																	// verifica erro na conex�o
				Self:SetError(cError,.T.,"MandaMail - MailSmtpOn")															// marca que houve erro
			EndIf
		Else
			Self:SetError("N�o foi informado nenhum destinat�rio",.F.,"MandaMail")								// marca que houve erro
		EndIf
	Else
		Self:SetError("N�o h� mensagem para ser enviada no e-mail",.F.,"MandaMail")								// marca que houve erro
	EndIf
Else
	Self:SetError("Conta de E-Mail n�o configurada",.F.,"MandaMail")											// marca que houve erro
EndIf
Return( Self:lError )

*=====================================================================================================================================*
Method Parametros() class EMail  // M�todo para configura��o dos par�metros no SX6
*=====================================================================================================================================*
local oDlg, nGrava:=0 , cTitulo:= "Par�metros para envio de Email"
local aSay := {},aGet := {} ,cVar:="" ,cBloco:="", i:=0
		//	aoGets = 		valor, linha, coluna, texto
private	aoGets:= {	{padr(AllTrim(GetMv("MV_RELSERV",," ")),120),"Servidor SMTP"       ,"MV_RELSERV",.f.},;
							{padr(AllTrim(GetMv("MV_RELACNT",," ")),120),"Conta remetente"     ,"MV_RELACNT",.f.},;
							{padr(AllTrim(GetMv("MV_RELPSW" ,," ")),120),"Senha remetente"     ,"MV_RELPSW" ,.t.},;
							{padr(Alltrim(GetMv("MV_RELAUSR",," ")),120),"Usu�rio Autenticador","MV_RELAUSR",.f.},;
							{padr(Alltrim(GetMv("MV_RELAPSW",," ")),120),"Senha Autenticador"  ,"MV_RELAPSW",.t.}}

Self:lAutentica := GetMv("MV_RELAUTH",,.F.)			//Determina se o Servidor de Email necessita de Autentica��o
Define MSDialog oDlg Title cTitulo						// defini��o da janela e suas propriedades
oDlg:nLeft		:=	0;	oDlg:nTop	:=	0					// a partir Canto Superior Esquerdo
oDlg:nWidth		:=	400										// Comprimento
oDlg:nHeight	:=	100 + Len(aoGets)*40					// Altura
oDlg:lCentered	:=	.T.

@ 02,060	BUTTON	"Gravar"	SIZE 40,10 ACTION ( nGrava:=1,oDlg:end() ) OF oDlg PIXEL  // bot�es de controle aparecem centralizados
@ 02,105	BUTTON	"Sair"	SIZE 40,10 ACTION ( nGrava:=0,oDlg:end() ) OF oDlg PIXEL  //

for i:= 1 to Len(aoGets)
	
	aadd( aSay, TSAY():Create(oDlg) )   // cria um label
	aSay[i]:cCaption := aoGets[i,2]     // com este texto
	aSay[i]:nLeft := 05                 // nestas posi��es
	aSay[i]:nTop := i*40
	aSay[i]:nWidth := 120
	aSay[i]:nHeight := 12
	
	cVar:="Var"+strZero(i,3,0)											// cria��o din�mica da nome da vari�vel
	&cVar := aoGets[i,1]													// cria��o din�mica da vari�vel
	cBloco := "{|u| If(PCount()>0,"+cvar+":=u,"+cvar+") }"	// cria��o do Code Block que associa a variavel ao get
	aadd( aGet,TGET():Create(oDlg) )									// cria o get
	aget[i]:nLeft		:=	aSay[i]:nLeft								// a propriedade bSetGet � respons�vel pela associa��o
	aget[i]:nTop		:=	aSay[i]:nTop + 18							// do Edit Box a vari�vel usando o code block definido
	aget[i]:nWidth		:=	oDlg:nWidth-30								// antes da cria��o do get, o nome desta vari�vel est�
	aget[i]:nHeight	:=	20												// declarado como str na prop. cVariable
	aget[i]:cVariable :=	cVar
	aget[i]:bSetGet	:=	&cBloco
	aget[i]:lPassWord	:=	aoGets[i,4]
	
next

@ 125,05 CHECKBOX Self:lAutentica Prompt "Servidor requer Autentica��o"  SIZE 120,08 PIXEL OF oDlg

oDlg:Activate()
If nGrava==1																											// a janela foi fechada usando o bot�o grava
	for i:= 1 to len(aoGets)
		cVar:="Var"+strZero(i,3,0)
		If !SetMv( Upper( aoGets[i,3]) , &cVar )																// o nome do par�metro deve ser sempre mai�sculo
			Self:SetError("Falha na grava��o do par�metro "+aoGets[i,3],.T.,"Par�metros")			// marca que houve erro
		EndIf
	next
	SetMv("MV_RELAUTH",Self:lAutentica)
	//
	If !Self:lError
		Self:cSMTPServer:= AllTrim(GetMv("MV_RELSERV"))														// nome do servidor
		Self:cMailconta := AllTrim(GetMv("MV_RELACNT"))														// remetente
		Self:cMailsenha := AllTrim(GetMv("MV_RELPSW"))														// senha do remetente
		Self:lAutentica := GetMv("MV_RELAUTH",,.F.)															// Determina se o Servidor de Email necessita de Autentica��o
		Self:cUserAut   := Alltrim(GetMv("MV_RELAUSR",," "))										  		// Usu�rio para Autentica��o no Servidor de Email
		Self:cPassAut   := Alltrim(GetMv("MV_RELAPSW",," "))										 		// Senha para Autentica��o no Servidor de Email
		//Self:SetError("Par�metros gravados com sucesso",Self:lError,"Par�metros")					// marca que n�o houve erro
		Self:SetError("Par�metros gravados com sucesso",Self:lError,"Par�metros")					// marca que n�o houve erro
	EndIf
	//
Else
	Self:SetError("A configura��o n�o foi alterada",Self:lError,"Par�metros")						// marca que houve erro
EndIf
return Self:lError

*=====================================================================================================================================*
Method SetError(cTexto,lErro,cMetodo) class EMail          // Marca a ocorr�ncia de erro
*=====================================================================================================================================*
	Default cTexto:="Erro indefinido"
	Self:cError:=cTexto
	Self:lError:=lErro
	Self:cErrorMet:=Upper(cMetodo)
    //AR   If Self:lExibeErro
    If Self:lExibeErro .And. Self:lError //AR
	   Self:ExibeErro()
	EndIf
return Self:lError

*=====================================================================================================================================*
Method SetGetShowErr(cOnOff) Class EMail
//	Funcionalidade:	M�todo com fun��o dupla. Este m�todo pode ser chamado atrav�s de um programa/rdmake desenvolvido pelo analista.
//							Este m�todo RETORNAR� qual a configura��o da exibi��o das mensagens de erro do objeto E-MAIL.
//							Para executar este m�todo, o objeto estar instanciado.
//							Chamada do m�todo				Par�metro		Retorno
//							---------------------		-------------	-------------------------------------------------------------------------------------------------
//							:SetGetShowErr()				nenhum			Retornar� a configura��o CORRENTE da exibi��o de erro do objeto (.T. para EXIBE, ou .F. para N�O EXIBE)
//							:SetGetShowErr('ON')			'ON'				Ir� ativar a exibi��o de erro do objeto
//							:SetGetShowErr('OFF')		'OFF'				Ir� desativar a exibi��o de erro do objeto
//							----------------------------------------------------------------------------------------------------------------------------------------
//							Observa��o: A interfer�ncia na configura��o da exibi��o de erro/alerta do objeto, via este m�todo, ir� afetar apenas a execu��o atual do mesmo.
*=====================================================================================================================================*
If valtype(cOnOff)=="C"
	cOnOff:= Trim(cOnOff)
	Self:lExibeErro := if( cOnOff=="ON",  .T., Self:lExibeErro )
	Self:lExibeErro := if( cOnOff=="OFF", .F., Self:lExibeErro )
EndIf
Return Self:lExibeErro

*=====================================================================================================================================*
Method ExibeErro() class EMail  // M�todo para exibi��o do aviso de erro 
*=====================================================================================================================================*
If !isBlind()
   If Self:lError
	   MsgStop(Self:cError,"Classe E-mail - M�todo "+AllTrim(Self:cErrorMet))
   Else 
	   MsgInfo(Self:cError,"Classe E-mail - M�todo "+AllTrim(Self:cErrorMet))
   EndIf
Else
   ConOut("["+DtoC(Date())+" || "+Time()+"] "+AllTrim(Self:cAssunto)+": Classe E-mail - M�todo "+AllTrim(Self:cErrorMet)+" <<< "+If(Self:lError,"ERRO","INFO")+" >>>: "+AllTrim(Self:cError))
EndIf
return Self:lError
