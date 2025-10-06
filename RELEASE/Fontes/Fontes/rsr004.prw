#INCLUDE "Protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "RSR004.CH"
   

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � RSR004   � Autor � Eduardo Ju            � Data � 14/07/06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Relatorio de Avaliacoes Realizadas Pelo Candidato          ���
�������������������������������������������������������������������������Ĵ��
���Sintaxe   � RSR004                                                     ���
�������������������������������������������������������������������������Ĵ��
���         ATUALIZACOES SOFRIDAS DESDE A CONSTRU�AO INICIAL.             ���
�������������������������������������������������������������������������Ĵ��
���Programador � Data   � BOPS �  Motivo da Alteracao                     ���
�������������������������������������������������������������������������Ĵ��
���Cecilia Car.�06/08/14�TQENRX�Incluido o fonte da 11 para a 12 e efetua-���
���            �        �      �da a limpeza.                             ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
����������������������������������������������������������������������������*/
User Function RSR004()

Local oReport
Local aArea := GetArea()

//��������������������������������������������������������������Ŀ
//� Verifica as perguntas selecionadas                           �
//����������������������������������������������������������������
Pergunte("RS04AR",.F.)
oReport := ReportDef()
oReport:PrintDialog()	

RestArea( aArea )

Return

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �ReportDef() � Autor � Eduardo Ju          � Data � 14.07.06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Definicao do Componente de Impressao do Relatorio           ���
�������������������������������������������������������������������������Ĵ��
���Parametros�                                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      �                                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/
Static Function ReportDef()

Local oReport
Local oSection1	
Local oSection2
Local cAliasQry := GetNextAlias()
Local cAliasQry1 := GetNextAlias()

//������������������������������������������������������������������������Ŀ
//�Criacao do componente de impressao                                      �
//�TReport():New                                                           �
//�ExpC1 : Nome do relatorio                                               �
//�ExpC2 : Titulo                                                          �
//�ExpC3 : Pergunte                                                        �
//�ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  �
//�ExpC5 : Descricao                                                       �
//��������������������������������������������������������������������������
oReport:=TReport():New("RSR004",STR0003,"RS04AR",{|oReport| PrintReport(oReport,cAliasQry,cAliasQry1)},STR0001+" "+STR0002)	//"Testes Realizados"#"Este programa tem como objetivo imprimir os testes realizados conforme parametros selecionados."
Pergunte("RS04AR",.F.) 
                                             
//����������������������������������������Ŀ
//� Criacao da Primeira Secao: Candidato   �
//������������������������������������������ 
oSection1 := TRSection():New(oReport,STR0009,{"SQR","SQG","SQQ"},/*aOrdem*/,/*Campos do SX3*/,/*Campos do SIX*/)	
oSection1:SetTotalInLine(.F.)  
oSection1:SetHeaderBreak(.T.)

TRCell():New(oSection1,"QR_FILIAL","SQR")				//Filial do Curriculo do Candidato
TRCell():New(oSection1,"QR_CURRIC","SQR",STR0010)		//Codigo do Curriculo do Candidato
TRCell():New(oSection1,"QG_NOME","SQG")					//Nome do Candidato
TRCell():New(oSection1,"QR_TESTE","SQR",STR0013)		//Codigo da Teste (Avaliacao)
TRCell():New(oSection1,"QQ_DESCRIC","SQQ","")			//Descricao da Avaliacao  

//���������������������������������������Ŀ
//� Criacao da Segunda Secao: Questoes    �
//����������������������������������������� 
oSection2:= TRSection():New(oSection1,STR0011,{"SQR"},/*aOrdem*/,/*Campos do SX3*/,/*Campos do SIX*/)	
oSection2:SetTotalInLine(.F.)  
oSection2:SetHeaderBreak(.T.)
oSection2:SetLeftMargin(2)	//Identacao da Secao
 
TRCell():New(oSection2,"QR_QUESTAO","SQR")				//Questao   
TRCell():New(oSection2,"QR_ALTERNA","SQR")				//Alternativa Selecionada   
TRCell():New(oSection2,"QO_PONTOS","SQO",STR0012) //Pontos de cada alternativa da questao

oSection2:SetTotalText({|| STR0014 })  //Nota
TRFunction():New(oSection2:Cell("QO_PONTOS"),/*cId*/,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,/*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)

Return oReport  

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �ReportDef() � Autor � Eduardo Ju          � Data � 07.07.06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Impressao do Relatorio                                      ���
�������������������������������������������������������������������������Ĵ��
���Parametros�                                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      �                                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/
Static Function PrintReport(oReport,cAliasQry,cAliasQry1)

Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(1):Section(1)  
Local cFiltro 	:= ""

//��������������������������������������������������������������Ŀ
//� Variaveis utilizadas para parametros                         �
//� mv_par01        //  Filial                                   � 
//� mv_par02        //  Curriculo                                � 
//� mv_par03        //  Teste                                    � 
//� mv_par04        //  Nota De                                  � 
//� mv_par05        //  Nota Ate                                 � 
//� mv_par06        //  Relatorio: Analitico ou Sintetico        � 
//����������������������������������������������������������������

//����������������������������������������������Ŀ
//� Transforma parametros Range em expressao SQL �
//������������������������������������������������
MakeSqlExpr("RS04AR")    

//-- Filtragem do relat�rio
//-- Query do relat�rio da secao 1
lQuery := .T.         
cOrder := "%QR_FILIAL,QR_CURRIC,QR_TESTE%"	
	
oReport:Section(1):BeginQuery()	

BeginSql Alias cAliasQry
	
SELECT DISTINCT	QR_FILIAL,QR_CURRIC,QG_NOME,QR_TESTE,QQ_DESCRIC
			
	FROM 	%table:SQR% SQR 
	
	LEFT JOIN %table:SQG% SQG
		ON QG_FILIAL = %xFilial:SQG%
		AND QG_CURRIC = QR_CURRIC
		AND SQG.%NotDel%
	LEFT JOIN %table:SQQ% SQQ
		ON QQ_FILIAL = %xFilial:SQQ%
		AND QQ_TESTE = QR_TESTE
		AND SQQ.%NotDel%    
	
	WHERE QR_FILIAL = %xFilial:SQR% AND 
		SQR.%NotDel%
	ORDER BY %Exp:cOrder%                 		
	
EndSql

//������������������������������������������������������������������������Ŀ
//�Metodo EndQuery ( Classe TRSection )                                    �
//�Prepara o relat�rio para executar o Embedded SQL.                       �
//�ExpA1 : Array com os parametros do tipo Range                           �
//��������������������������������������������������������������������������
oReport:Section(1):EndQuery({mv_par01,mv_par02,mv_par03})	/*Array com os parametros do tipo Range*/

BEGIN REPORT QUERY oReport:Section(1):Section(1)

BeginSql Alias cAliasQry1
	
SELECT QR_QUESTAO,QR_ALTERNA,(QR_RESULTA*QO_PONTOS)/100 AS QO_PONTOS
			
	FROM 	%table:SQR% SQR, %table:SQO% SQO
	
	WHERE QR_FILIAL = %xFilial:SQR% AND QO_FILIAL = %xFilial:SQO% AND
		QR_CURRIC = %report_param:(cAliasQry)->QR_CURRIC% AND
		QR_TESTE = %report_param:(cAliasQry)->QR_TESTE% AND
		QO_FILIAL = QR_FILIAL AND
		QO_QUESTAO = QR_QUESTAO AND
		SQR.%NotDel% AND
		SQO.%NotDel%
	ORDER BY %Exp:cOrder%
	
EndSql

END REPORT QUERY oReport:Section(1):Section(1)

//�������������������������������������������Ŀ         																																																																																
//� Inicio da impressao do fluxo do relat�rio �
//���������������������������������������������
 	oReport:SetMeter(SQR->(LastRec()))

//���������������������������Ŀ
//� Condicao para Impressao   �
//�����������������������������
oSection1:SetLineCondition({|| Rs004Nota(cAliasQry,oReport:Section(1):Section(1)) })
               
If mv_par06 = 2	//Sintetico Obs.: Apresenta apenas Nota
	oSection2:Hide()
	oSection2:Cell("QR_QUESTAO"):HideHeader()
	oSection2:Cell("QR_ALTERNA"):HideHeader()
	oSection2:Cell("QO_PONTOS"):HideHeader()
EndIf

oReport:SetMeter(SQR->(LastRec()))	   

oSection1:Print() //Imprimir   

Return Nil

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    �Rs004Pontos � Autor � Eduardo Ju          � Data � 29.08.06 ���
�������������������������������������������������������������������������Ĵ��
���Descricao �Calculo da Nota                                             ���
�������������������������������������������������������������������������Ĵ��
���Parametros�                                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � APDR50                                                     ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/
Static Function Rs004Pontos(cAliasQry)

Local nPontos 	:= 0
Local cSvAlias 	:= Alias()  

nPontos:= ( ((cAliasQry)->QO_PONTOS * (cAliasQry)->QR_RESULTA) / 100 )

DbSelectArea(cSvAlias)

Return nPontos  

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    �Rs004Nota   � Autor � Eduardo Ju          � Data � 29.08.06 ���
�������������������������������������������������������������������������Ĵ��
���Descricao �Impressao da Nota                                           ���
�������������������������������������������������������������������������Ĵ��
���Parametros�                                                            ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � RSR004                                                     ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/
Static Function Rs004Nota(cAliasQry,oPontos)

Local nNota 	:= 0
Local cSvAlias 	:= Alias()
Local lNota		:= .F.

oPontos:ExecSql()
While !Eof()
	nNota += (oPontos:cAlias)->QO_PONTOS
	DbSkip()
End

If nNota >= mv_par04 .And.  nNota <= mv_par05
	lNota	:= .T.
EndIf 

DbSelectArea(cSvAlias)

Return lNota    