#INCLUDE 'TOTVS.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOPCONN.CH'
#include "Ap5Mail.ch"

#DEFINE IMP_PDF 6

/*/{Protheus.doc} DORMAILPC

description

@type function
@version  
@author Sato
@since 22/02/2024
@param nRecSC7, numeric, param_description
@return variant, return_description
/*/
User Function DORMAILPC( nRecSC7 as Numeric )

local   cArquivo    as Character
local   cRet        as Character
local   cFilNom     as Character
local   cForNom     as Character
local   cMailContr  as Character
local   cDestino    as Character
local   cCopia      as Character

SC7->( DbGoto(nRecSC7) )

private cWFLFilial  := SC7->C7_FILIAL
private cWFLNum     := SC7->C7_NUM
private cWFLData    := ddatabase
private cWFLMsg1    := ''
private cWFLEmailF  := ''
private cWFLEmailC  := ''
private cWFLStaGer  := ''
private cWFLMsg2    := ''
private cWFLStaEnv  := ''
private cWFLMsg3    := ''
private cWFLRotina  := 'DORMAILPC'
private cWFLHora    := time() 
private cWFLArq 	:= '' 
private cWFLRecn	:= nRecSC7 
private cWFLCdFor	:= SC7->C7_FORNECE  
private cWFLLjFor	:= SC7->C7_LOJA  
private cWFLFornec	:= "" 
private cWFLNumCon	:= ""
private cWFLRevisa	:= ""
private cWFLTabPrc	:= ""
private cWFLUsuario	:= Alltrim(USRFULLNAME(__cuserid)) 

cArquivo := ''
aAreaSA2 := SA2->( getarea( 'SA2' ))
cRet     := ''
cFilNom  := alltrim( fwfilialname( cEmpAnt , SC7->C7_FILIAL , 1 ))
cForNom  := ''
cDestino := ''
cCopia   := ''


If SC7->C7_CONAPRO = 'L'
	If SC7->C7_RESIDUO <> 'S'

		//cWFLFornec := alltrim( GetAdvFval("SA2", "A2_NREDUZ", FWxFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA, 1) )

		SA2->( dbSetOrder(1) )     // A2_FILIAL + A2_COD + A2_LOJA
		SA2->( dbGoTop() )
		SA2->( dbseek( FWxFilial('SA2') + SC7->C7_FORNECE + SC7->C7_LOJA ) )

		cWFLFornec := alltrim( SA2->A2_NREDUZ )

		if empty( alltrim(SA2->A2_EMAIL) ) .and. empty( alltrim(SC7->C7_XMAILFO) ) .and. empty( alltrim(SC7->C7_GRUPCOM) )
			cWFLMsg1 := 'N�O OK (1.1) - Conta de email n�o cadastrada no fornecedor!'
			cWFLStaGer := 'ERRO'
			sndPrepErr(SC7->C7_NUM,nRecSC7,"Conta de email n�o cadastrada no fornecedor ",1) 
		else
			If !empty( alltrim(SA2->A2_EMAIL) )
				cDestino := alltrim(SA2->A2_EMAIL)
			EndIf
			If !empty( alltrim(SC7->C7_XMAILFO) )
				If !empty( cDestino )
					cDestino := cDestino+";"+alltrim(SC7->C7_XMAILFO)
				Else
					cDestino := alltrim(SC7->C7_XMAILFO)
				EndIf
			EndIf

			dbSelectArea("SZJ")
			SZJ->( dbSetOrder(1) )     // ZJ_FILIAL + ZJ_GRCOM
			SZJ->( dbGoTop() )
			If SZJ->( dbseek( FWxFilial('SZJ') + SC7->C7_GRUPCOM ) )
				cCopia := SZJ->ZJ_EMAIL
			EndIf

			cForNom    := alltrim( SA2->A2_NREDUZ )
			cWFLMsg1   := 'OK (1.0) - Pedido Liberado! Email do fornecedor informado!'
			cWFLEmailF := cDestino
			cWFLEmailC := cCopia
			cMailContr := cCopia

			cArquivo := u_tewbtyr2( 'SC7' , nRecSC7 , Nil , 1 )
			cWFLArq    := cArquivo 

			if vldarquivo(cArquivo,nRecSC7)

				cRet := preparaemail(   cDestino    , ;
				cArquivo    , ;
				SC7->C7_NUM , ;
				cMailContr  , ;
				nRecSC7     , ;
				cFilNom     , ;
				cForNom     )

				if !empty( cRet )
					sndPrepErr(SC7->C7_NUM,nRecSC7,cRet,2) 
				endif

			else
				sndmailerr( SC7->C7_NUM , nRecSC7 )
			endif

		endif
	else
		cWFLMsg1 := 'N�O OK (1.3) - Pedido n�o foi gerado, pois foi eliminado residuo'
	endif
else
	cWFLMsg1 := 'N�O OK (1.2) - Pedido n�o foi gerado devido a estar bloqueado'
endif

recLock( 'WFL' , .T. )
WFL->WFL_FILIAL := cWFLFilial
WFL->WFL_NUM    := cWFLNum
WFL->WFL_DATA   := cWFLData
WFL->WFL_MSG1   := cWFLMsg1
WFL->WFL_EMAILF := cWFLEmailF
WFL->WFL_EMAILC := cWFLEmailC
WFL->WFL_STAGER := cWFLStaGer
WFL->WFL_MSG2   := cWFLMsg2
WFL->WFL_STAENV := cWFLStaEnv
WFL->WFL_MSG3   := cWFLMsg3
WFL->WFL_ROTINA := cWFLRotina
WFL->WFL_HORA   := cWFLHora 
WFL->WFL_ARQUIV := cWFLArq 
WFL->WFL_RECNC7 := cValToChar(cWFLRecn) 
WFL->WFL_CODFOR	:= cWFLCdFor 
WFL->WFL_LOJFOR	:= cWFLLjFor 
WFL->WFL_FORNEC	:= cWFLFornec 
WFL->WFL_NUMCON	:= cWFLNumCon 
WFL->WFL_REVISA	:= cWFLRevisa 
WFL->WFL_TABPRC := cWFLTabPrc 
WFL->WFL_USER   := cWFLUsuario 
WFL->( msunlock() )

return .T.


static function preparaemail( cContaDes , cArquivo , cNumPC , cMailContr , nRecSC7 , cFilNom , cForNom )


	local cSMTP     := alltrim( getmv( 'MV_RELSERV' )) // smtp.ig.com.br ou 200.181.100.51
	local cConta    := alltrim( getmv( 'MV_RELACNT' )) // fulano@ig.com.br
	local cPass     := alltrim( getmv( 'MV_RELPSW'  )) // 123abc
	local cAssunto  := 'Pedido de compra: ' + cNumPC  + ;
	' - Filial: ' + cFilNom + ;
	' - Fornecedor: ' + cForNom
	local cCorpo    := alltrim( getmv( 'FS_EF12005' , , 'Caro fornecedor, <br> Anexo, enviamos o espelho do Pedido de Compra para seu conhecimento.<br>' ))
	local cRet      := ''
	local cMensagem := ''
	Local _cNomAux := ""
	Local _cArqAux := ""

	aAreaC7 := GetArea()
	dbselectarea( 'SC7' )
	SC7->( dbGoto( nRecSC7 ))
	_cNomAux := SC7->C7_FILIAL+SC7->C7_NUM+SC7->C7_FORNECE+SC7->C7_LOJA
	RestArea(aAreaC7)

	_cArqAux := Substr(StrTran(cArquivo,".pdf",""),-Len(_cNomAux))
	If _cArqAux <> _cNomAux
		cRet := "Filial, Pedido, Fornecedor ou Loja do Nome do Arquivo divergente do Pedido."
		cWFLStaGer := 'ERRO'
		cWFLMsg2   := 'N�O OK (3.1) - Filial, Pedido, Fornecedor ou Loja do Nome do Arquivo divergente do Pedido.'
	EndIf
	If cNumPC <> SC7->C7_NUM .OR. cFilNom <> alltrim( fwfilialname( cEmpAnt , SC7->C7_FILIAL , 1 )) .OR. cForNom <> Alltrim(POSICIONE("SA2",1,xfilial( 'SA2' )+SC7->(C7_FORNECE + C7_LOJA),"A2_NREDUZ"))
		cRet := "Filial, Pedido ou Fornecedor do Assunto do E-mail diferente do Pedido."
		cWFLStaGer := 'ERRO'
		cWFLMsg2   := 'N�O OK (3.1) - Filial, Pedido ou Fornecedor do Assunto do E-mail diferente do Pedido.'
	EndIf

	If Empty(Alltrim(cRet))
		cMensagem := '<html>'
		cMensagem += '<head><title>' + alltrim( cAssunto ) + '</title></head>'
		cMensagem += '<body>'
		cMensagem += '<br>'
		cMensagem += cCorpo
		cMensagem += '<br>'
		cMensagem += '</body>'
		cMensagem += '</html>'

		cRet := enviaemail( cSMTP      , ;
		cConta     , ;
		cPass      , ;
		cContaDes  , ;
		cAssunto   , ;
		cArquivo   , ;
		cMensagem  , ;
		cMailContr , ;
		nRecSC7      )

	EndIf

return cRet



static function enviaemail( cSMTP , cConta , cPass , cContaDes , cAssunto , cArquivo , cMensagem , cMailContr , nRecSC7 )

	local lConSMTP   := .t.
	local lEnvEmail  := .t.
	local cError     := ''
	local cRet       := ''
	local cNomeAnexo := cArquivo
	Local nSMTPTime:= 200
	Local _cBcc      := Alltrim(SuperGetMV('MV_XPCCCO', .F., ""))
	Local nSMTPPort 	:= GetMV("MV_GCPPORT",, 25)
	Local _cEmail    := ""

	//    Connect SMTP Server cSMTP Account cConta Password cPass Result lConSMTP
	//Objeto de Email
	oServer := tMailManager():New()


	nErr := oServer:init("",cSMTP, cConta,cPass,nSMTPPort)
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar: 	
		lConSMTP:= .f.
	Endif


	If oServer:SetSMTPTimeout(nSMTPTime) != 0
		alert("Falha ao definir timeout") // Falha ao definir timeout
		lConSMTP:= .f.
	EndIf


	nErr := oServer:smtpConnect()
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar:		
		oServer:SMTPDisconnect()
		lConSMTP:= .f.
	EndIf




	nErr := oServer:smtpAuth(cConta,cPass)
	If nErr <> 0		
		alert("Falha ao autenticar: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
		oServer:SMTPDisconnect() 
		lConSMTP:= .f.
	EndIf



	// Cria uma nova mensagem (TMailMessage)
	oMessage := tMailMessage():new()
	oMessage:clear()        






	if lConSMTP

		cNomeAnexo := '\workflow\' + substr( cArquivo , rat( '\' , cArquivo ) + 1 )

		if !ExistDir( '\workflow' )
			makedir( '\workflow' )
		endif

		cpyt2s( cArquivo , '\workflow\' , .T. )

		Do Case
			Case Empty( cMailContr ) .AND. Empty( _cBcc )
			//	SEND MAIL FROM cConta TO cContaDes               SUBJECT cAssunto BODY cMensagem ATTACHMENT cNomeAnexo Result lEnvEmail


			// Dados da mensagem		
			oMessage:cFrom		:= cConta
			oMessage:cTo     	:=  cContaDes
			oMessage:cSubject	:= cAssunto
			oMessage:cBody   	:= cMensagem
			oMessage:AttachFile(cNomeAnexo)		

			Case !Empty( cMailContr ) .AND. Empty( _cBcc )
			//	SEND MAIL FROM cConta TO cContaDes CC cMailContr SUBJECT cAssunto BODY cMensagem ATTACHMENT cNomeAnexo Result lEnvEmail

			// Dados da mensagem		
			oMessage:cFrom		:= cConta
			oMessage:cTo     	:=  cContaDes
			oMessage:cCC    	:=  cMailContr
			oMessage:cSubject	:= cAssunto
			oMessage:cBody   	:= cMensagem
			oMessage:AttachFile(cNomeAnexo)		


			Case Empty( cMailContr ) .AND. !Empty( _cBcc )
			//SEND MAIL FROM cConta TO cContaDes BCC _cBcc SUBJECT cAssunto BODY cMensagem ATTACHMENT cNomeAnexo Result lEnvEmail

			// Dados da mensagem		
			oMessage:cFrom		:= cConta
			oMessage:cTo     	:=  cContaDes
			oMessage:cBCC   	:=  _cBcc
			oMessage:cSubject	:= cAssunto
			oMessage:cBody   	:= cMensagem
			oMessage:AttachFile(cNomeAnexo)		


			Otherwise
			//SEND MAIL FROM cConta TO cContaDes CC cMailContr BCC _cBcc SUBJECT cAssunto BODY cMensagem ATTACHMENT cNomeAnexo Result lEnvEmail


			// Dados da mensagem		
			oMessage:cFrom		:= cConta
			oMessage:cTo     	:=  cContaDes
			oMessage:cCC    	:=  cMailContr
			oMessage:cBCC   	:=  _cBcc
			oMessage:cSubject	:= cAssunto
			oMessage:cBody   	:= cMensagem
			oMessage:AttachFile(cNomeAnexo)

		EndCase

		nErr := oMessage:send(oServer)
		If nErr <> 0		
			alert("Falha ao Enviar MSg: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
			oServer:SMTPDisconnect() 
			lEnvEmail:= .f.
		EndIf


		dbselectarea( 'SC7' )
		SC7->( dbSetOrder(1) )
		SC7->( dbGoTop() )

		if !lEnvEmail // Erro no envio do email


			cRet := 'Erro no envio do email: ' + cError

			cWFLStaEnv := 'ERRO'
			cWFLMsg3   := 'N�O OK (3.2) - ' + cRet

			If SC7->( dbseek( cWFLFilial + cWFLNum ) )
				Do While SC7->(!Eof()) .and. SC7->C7_FILIAL == cWFLFilial .and.  SC7->C7_NUM == cWFLNum
					reclock( 'SC7' , .F. )
					SC7->C7_XENVMAL := 'N'
					SC7->( msunlock() )

					SC7->( dbSkip() )
				EndDo
			EndIf

		else

			cWFLStaEnv := 'OK'
			cWFLMsg3   := 'OK (3.0) - Conex�o SMTP OK! Email enviado!'

			If SC7->( dbseek( cWFLFilial + cWFLNum ) )
				Do While SC7->(!Eof()) .and. SC7->C7_FILIAL == cWFLFilial .and.  SC7->C7_NUM == cWFLNum
					reclock( 'SC7' , .F. )
					SC7->C7_XENVMAL := 'S'
					SC7->( msunlock() )

					SC7->( dbSkip() )
				EndDo
			EndIf

			_cEmail := SalvaEmail(cConta,cContaDes,cMailContr,_cBcc,cAssunto,cMensagem,cNomeAnexo) 
			If !Empty(Alltrim(_cEmail)) .AND. !IsInCallStack( 'U_F1200600' )
				cpyt2s( _cEmail , '\workflow\' , .T. )
			EndIf

		endif

		SC7->( dbGoto(nRecSC7) )

		// Desconecta do Servidor
		oServer:smtpDisconnect() 

	else

		//Get Mail Error cError
		cRet := 'Erro na conex�o SMTP: ' + cError
		cWFLStaEnv := 'ERRO'
		cWFLMsg3   := 'N�O OK (3.1) - ' + cRet
	endif

return cRet




static function vldarquivo(cArquivo,nRecSC7)

	local nHandle := 0
	local lRet    := .T.
	local nTam    := 0
	local nTry    := 1
	Local _cNomAux := ""
	Local _cArqAux := ""

	nHandle := fopen( cArquivo )

	do while ( nTry    <=  5 .AND. ;
	nHandle == -1       )

		nTry++
		sleep( 1000 )
		nHandle := fopen( cArquivo )

	enddo

	if nHandle <> -1

		nTam := fseek( nHandle , 0 , 2 ) // Determina o tamanho do arquivo
		nTry := 1

		do while ( nTry <= 5 .AND. ;
		nTam == 0       )

			nTry++
			sleep( 1000 )
			nTam := fseek( nHandle , 0 , 2 ) // Nova leitura do tamanho do arquivo (verificao de inicio da escrita)

		enddo

		sleep( 1000 )

		if nTam > 0 	

			nTry := 1

			// ------------------------------------
			//          [ Validacao para garantir que o arquivo foi escrito por completo              ]
			//          [ a cada 1 segundo, mudara o conteudo dele com relacao a verificacao anterior ]
			// ------------------------------------
			do while ( nTry                     <= 40 .AND. ;
			fseek( nHandle , 0 , 2 ) <> nTam     )

				nTry++
				nTam := fseek( nHandle , 0 , 2 )
				sleep( 1000 )

			enddo

			lRet := ( fseek( nHandle , 0 , 2 ) == nTam .AND. ;
			nTry                     <= 40         )

			if lRet
				cWFLStaGer := 'OK'
				cWFLMsg2   := 'OK (2.0) - Arquivo OK!'
			else
				cWFLStaGer := 'ERRO'
				cWFLMsg2   := 'N�O OK (2.3) - Arquivo incompleto.'
			endif
		else
			lRet := .F.

			cWFLStaGer := 'ERRO'
			cWFLMsg2   := 'N�O OK (2.2) - Arquivo vazio.'
		endif

		fclose( nHandle )
	else
		lRet := .F.

		cWFLStaGer := 'ERRO'
		cWFLMsg2   := 'N�O OK (2.1) - N�o � poss�vel abrir o arquivo gerado.'
	endif

	If lRet
		_aAreaC7 := GetArea()
		DbSelectArea("SC7")
		SC7->(dbgoto( nRecSC7 ))
		_cNomAux := SC7->C7_FILIAL+SC7->C7_NUM+SC7->C7_FORNECE+SC7->C7_LOJA
		RestArea(_aAreaC7)
		_cArqAux := Substr(StrTran(cArquivo,".pdf",""),-Len(_cNomAux))
		If _cArqAux <> _cNomAux
			lRet := .F.
			cWFLStaGer := 'ERRO'
			cWFLMsg2   := 'N�O OK (2.4) - Filial, Pedido, Fornecedor ou Loja do Nome do Arquivo divergente do Pedido.'
		EndIf
	EndIf
	if !lRet
		ferase( cArquivo )
	endif
return lRet



static function sndmailerr( cNumPC , nRecSC7 )

	local cSMTP     := alltrim( getmv( 'MV_RELSERV' )) // smtp.ig.com.br ou 200.181.100.51
	local cConta    := alltrim( getmv( 'MV_RELACNT' )) // fulano@ig.com.br
	local cPass     := alltrim( getmv( 'MV_RELPSW'  )) // 123abc
	Local nSMTPPort 	:= GetMV("MV_GCPPORT",, 25)
	Local nSMTPTime:= 200
	local cAssunto  := ''
	local cMensagem := ''
	local lConSMTP  := .F.

	dbselectarea( 'SC7' ) // Ped.Compra / Aut.Entrega
	SC7->( dbgoto( nRecSC7 ))

	cAssunto  := 'Erro ao enviar PDF de pedido de compra: ' + cNumPC

	cMensagem := '<html>'
	cMensagem += '<head><title>' + cAssunto + '</title></head>'
	cMensagem += '<body>'
	cMensagem += '<br>'
	cMensagem += 'Ocorreu um erro ao gerar o arquivo PDF do pedido: ' + cNumPC + ' da filial ' + SM0->M0_FILIAL
	cMensagem += ' para o fornecedor ' + posicione( 'SA2' , 1 , xfilial( 'SA2' ) + SC7->C7_FORNECE + SC7->C7_LOJA , 'A2_NOME' )
	cMensagem += ', � necess�rio imprimir o mesmo no sistema e enviar em anexo a um e-mail para o fornecedor novamente.<br><br><br>'
	cMensagem += '</body>'
	cMensagem += '</html>'




	// Objeto de Email
	oServer := tMailManager():New()


	nErr := oServer:init("",cSMTP, cConta,cPass,,nSMTPPort)
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar: 	

	Endif


	If oServer:SetSMTPTimeout(nSMTPTime) != 0
		alert("Falha ao definir timeout") // Falha ao definir timeout

	EndIf


	nErr := oServer:smtpConnect()
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar:		
		oServer:SMTPDisconnect()

	EndIf


	nErr := oServer:smtpAuth(cConta,cPass)
	If nErr <> 0		
		alert("Falha ao autenticar: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
		oServer:SMTPDisconnect() 
	EndIf



	//	SEND MAIL FROM cConta TO alltrim( getmv( 'MV_XMAILFO' )) SUBJECT cAssunto BODY  cMensagem

	// Cria uma nova mensagem (TMailMessage)
	oMessage := tMailMessage():new()
	oMessage:clear()        


	// Dados da mensagem		
	oMessage:cFrom		:= cConta
	oMessage:cTo     	:=  alltrim( getmv( 'MV_XMAILFO' ))
	oMessage:cSubject	:= cAssunto
	oMessage:cBody   	:= cMensagem



	nErr := oMessage:send(oServer)
	If nErr <> 0		
		alert("Falha ao Enviar MSg: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
		oServer:SMTPDisconnect() 
	EndIf

	// Desconecta do Servidor
	oServer:smtpDisconnect() 




	If SC7->( dbseek( cWFLFilial + cWFLNum ) )
		Do While SC7->(!Eof()) .and. SC7->C7_FILIAL == cWFLFilial .and.  SC7->C7_NUM == cWFLNum
			reclock( 'SC7' , .F. )
			SC7->C7_XENVMAL := 'N'
			SC7->( msunlock() )

			SC7->( dbSkip() )
		EndDo
	EndIf


return




static function sndPrepErr(cNumPC,nRecSC7,cMsg,nTp)

	local cSMTP     := alltrim( getmv( 'MV_RELSERV' )) // smtp.ig.com.br ou 200.181.100.51
	local cConta    := alltrim( getmv( 'MV_RELACNT' )) // fulano@ig.com.br
	local cPass     := alltrim( getmv( 'MV_RELPSW'  )) // 123abc
		Local nSMTPPort 	:= GetMV("MV_GCPPORT",, 25)
	Local nSMTPTime:= 200
	local cAssunto  := ''
	local cMensagem := ''
	local lConSMTP  := .F.

	dbselectarea( 'SC7' ) // Ped.Compra / Aut.Entrega
	SC7->( dbgoto( nRecSC7 ))

	If nTp == 2
		cAssunto  := 'Erro ao preparar/enviar E-mail de pedido de compra: ' + cNumPC
	Else
		cAssunto  := cMsg +' do Pedido de Compra: ' + cNumPC
	EndIf

	cMensagem := '<html>'
	cMensagem += '<head><title>' + cAssunto + '</title></head>'
	cMensagem += '<body>'
	cMensagem += '<br>'
	If nTp == 2
		cMensagem += 'Ocorreu um erro na montagem/envio do e-mail do pedido: ' + cNumPC + ' da filial ' + SC7->C7_FILIAL
		cMensagem += ' para o fornecedor ' + posicione( 'SA2' , 1 , xfilial( 'SA2' ) + SC7->C7_FORNECE + SC7->C7_LOJA , 'A2_NOME' )
		cMensagem += ', � necess�rio imprimir o mesmo no sistema e enviar em anexo a um e-mail para o fornecedor novamente.<br><br>'
		cMensagem += 'Segue erro informado: ' + Alltrim(cMsg)
	Else
		cMensagem += 'O Fornecedor: '+ posicione( 'SA2' , 1 , xfilial( 'SA2' ) + SC7->C7_FORNECE + SC7->C7_LOJA , 'A2_NOME' )
		cMensagem += ' n�o possui e-mail cadastrado. Ser� necess�rio imprimir o Pedido de Compra no sistema e'
		cMensagem += ' enviar em anexo a um e-mail para o fornecedor novamente. <br> '
		cMensagem += 'Para que o problema n�o ocorra novamente deve-se atualizar o Cadastro do Fornecedor informando uma conta de e-mail. <br><br> '
	EndIf
	cMensagem += '<br><br><br>'
	cMensagem += '</body>'
	cMensagem += '</html>'

//	Connect SMTP Server cSMTP Account cConta Password cPass Result lConSMTP



	// Objeto de Email
	oServer := tMailManager():New()


	nErr := oServer:init("",cSMTP, cConta,cPass,,nSMTPPort)
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar: 	

	Endif


	If oServer:SetSMTPTimeout(nSMTPTime) != 0
		alert("Falha ao definir timeout") // Falha ao definir timeout

	EndIf


	nErr := oServer:smtpConnect()
	If nErr <> 0	
		alert("Falha ao conectar:" + oServer:getErrorString(nErr)) // Falha ao conectar:		
		oServer:SMTPDisconnect()

	EndIf


	nErr := oServer:smtpAuth(cConta,cPass)
	If nErr <> 0		
		alert("Falha ao autenticar: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
		oServer:SMTPDisconnect() 
	EndIf




//	if lConSMTP
//		SEND MAIL FROM cConta TO alltrim( getmv( 'MV_XMAILFO' )) SUBJECT cAssunto BODY  cMensagem

// Cria uma nova mensagem (TMailMessage)
	oMessage := tMailMessage():new()
	oMessage:clear()        


	// Dados da mensagem		
	oMessage:cFrom		:= cConta
	oMessage:cTo     	:=  alltrim( getmv( 'MV_XMAILFO' ))
	oMessage:cSubject	:= cAssunto
	oMessage:cBody   	:= cMensagem



	nErr := oMessage:send(oServer)
	If nErr <> 0		
		alert("Falha ao Enviar MSg: " + oServer:getErrorString(nErr)) // Falha ao autenticar: 
		oServer:SMTPDisconnect() 
	EndIf

	// Desconecta do Servidor
	oServer:smtpDisconnect() 

		If SC7->( dbseek( cWFLFilial + cWFLNum ) )
			Do While SC7->(!Eof()) .and. SC7->C7_FILIAL == cWFLFilial .and.  SC7->C7_NUM == cWFLNum
				reclock( 'SC7' , .F. )
				SC7->C7_XENVMAL := 'N'
				SC7->( msunlock() )

				SC7->( dbSkip() )
			EndDo
		EndIf
//		Disconnect SMTP Server
//	endif
return




Static Function SalvaEmail(cConta,cContaDes,cMailContr,_cBcc,cAssunto,cMensagem,cNomeAnexo)
	Local _cNomeArq := 'EMAIL'
	Local oPrinter
	local cDir            := '\IMPPC\'
	Local lAdjustToLegacy := .F. 
	Local lDisableSetup  := .T.
	Local _cNomeAux := substr( cNomeAnexo , rat( '\' , cNomeAnexo ) + 1 )
	Local cAuxMsg := {}

	if !ExistDir( '\IMPPC' ) 
		MakeDir( '\IMPPC' ) 
	endif 

	_cNomeArq += StrTran(_cNomeAux,"RDRIMPPC","")
	_cNomeArq := StrTran(_cNomeArq,".pdf","")

	cAuxMsg := StrTran(cMensagem,cAssunto,"")
	cAuxMsg := StrTran(cAuxMsg,"<body>","")
	cAuxMsg := StrTran(cAuxMsg,"<html>","")
	cAuxMsg := StrTran(cAuxMsg,"<head>","")
	cAuxMsg := StrTran(cAuxMsg,"<title>","")
	cAuxMsg := StrTran(cAuxMsg,"</title>","")
	cAuxMsg := StrTran(cAuxMsg,"</head>","")
	cAuxMsg := StrTran(cAuxMsg,"<br>"," ")
	cAuxMsg := StrTran(cAuxMsg,"</body>","")
	cAuxMsg := StrTran(cAuxMsg,"</html>","")
	cMensagem := StrTran(cAuxMsg,"  "," ")
	cMensagem := Alltrim(cMensagem)

	oPrinter := FWMSPrinter():New(_cNomeArq, IMP_PDF, lAdjustToLegacy, cDir, lDisableSetup , , , , , , .F. , .F. )
	oPrinter:SetPortrait()

	oFont09  := TFont():New( 'Arial'       , 09 , 09 , , .F. , , , , .T. , .F. )

	oPrinter:StartPage()

	oPrinter:Say(015,10,"INFORMA��ES DO E-MAIL ENVIADO", oFont09 ) 
	oPrinter:Line(017 , 10 , 015 , 0580 )
	oPrinter:Say(030,10,"De: "+cConta, oFont09 ) // conteudo
	oPrinter:Say(040,10,"Para: "+cContaDes, oFont09 ) // conteudo
	oPrinter:Say(050,10,"CC: "+IIf(Empty(Alltrim(cMailContr)),"N/A",cMailContr), oFont09) // conteudo
	oPrinter:Say(060,10,"BCC: "+IIf(Empty(Alltrim(_cBcc)),"N/A",_cBcc), oFont09 ) // conteudo
	oPrinter:Say(070,10,"Assunto: "+cAssunto, oFont09 ) // conteudo
	oPrinter:Say(080,10,"Mensagem: "+Substr(cMensagem,1,150), oFont09 ) // conteudo
	If Len(cMensagem) > 150
		oPrinter:Say(090,10,"          "+Substr(cMensagem,151,150), oFont09 ) // conteudo
	EndIf
	If Len(cMensagem) > 250
		oPrinter:Say(100,10,"          "+Substr(cMensagem,301), oFont09 ) // conteudo
	EndIf
	oPrinter:Say(110,10,"Nome Anexo: "+cNomeAnexo, oFont09 ) // conteudo

	oPrinter:Line(0128 , 010 , 0128 , 0580 )
	oPrinter:Say( 0135 , 0010 , 'TOTVS - F1200501 - SalvaEmail' , oFont09 )
	oPrinter:Line(0137 , 0010 , 0137 , 0580 )
	oPrinter:Preview() // depois de salvar abre o arquivo na tela

	oPrinter:EndPage()

Return oPrinter:cPathPDF + _cNomeArq + '.pdf'

