#Include 'Protheus.ch' 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWBROWSE.CH"
#include "ap5mail.ch"

Static lESalPrp		:= .F. //.T. Indica que existe altera��o salarial
Static lECarPrp		:= .F. //.T. Indica que existe altera��o de Cargo
Static lETurPrp		:= .F. //.T. Indica que existe altera��o de Turno        
Static lETrfPrp		:= .F. //.T. Indica que existe transfer�ncia         
Static lEHorPrp		:= .F. //.T. Indica que existe altera��o de Carga Hor�ria		
Static lValPosto	:= .T. //.T. Indica que o posto � v�lido, portanto possui vaga dispon�vel
Static cSubGrp	    := ''  //Codigo do subgrupo
Static cDepSolc		:= ''
Static lBOracle		:= Trim(TcGetDb()) = 'ORACLE'
Static cTipOrgA		:= GetMV('MV_ORGCFG')//1- por posto, 2 - por departamento 0-n�o tem integra��o
Static cClasVlA		:= GetMV('MV_ITMCLVL')//1 � Utiliza Item Cont�bil e Classe de Valores.,2 � N�o Utiliza Item Cont�bil e Classe de Valores.
Static aMotivo		:= {}
Static TSRA	 

/*{Protheus.doc} F0500401
Movimenta�oes de Pessoas - centralizador de solicita��es tipo: Altera��o Salarial, Cargo, Carga Hor�ria, Turno e/ou Transfer�ncia

@author Cris
@since 20/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}

*/
User Function F0500401()
	
	Local cMat 			:= ""
	Local aAux 			:= {}
	Local cAliasSra  	:= GetNextAlias()
	Local aSize			:= FWGetDialogSize( oMainWnd )				// Tamanho da tela
	Local aRotina		:= {} 
	Local aIndex		:= {}
	Local aSeek			:= {}
	Local aFieFilter	:= {} 
	Local cVeSal		:= GetMV("MV_XVESAL")		// Siqueira 03/04/24                    

	Local aStruSRA  := {} //MRF
	Local aStruFun  := SRA->( dbStruct() )  //MRF
    Local nI		:= 0
    
    AAdd(aSeek, {"Matr�cula"   	, {{"", "C", TamSX3("RA_MAT")[1] , 0, "Matr�cula"   , , }}, 1, .T.})	
    AAdd(aSeek, {"Nome"			, {{"", "C", TamSX3("RA_NOME")[1], 0, "Nome"		, , }}, 2, .T.})
	
    AAdd(aIndex, "RA_MAT" )
    AAdd(aIndex, "RA_NOME")	
        
	cMat := RetFunc()

    //Inicio MRF	
	dbUseArea( .T., 'TOPCONN', TcGenQry( ,, cMat ) , cAliasSra, .T., .F. )

	If !( cAliasSra )->( EOF() )
	
		// Cria a fisicamente a tabela de trabalho
		SRA->( dbSetOrder( 1 ) )  //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

		//SX3->( dbSetOrder( 2 ) )             
		
		_cCmp := "RA_FILIAL|RA_MAT|RA_NOME|RA_NASC|RA_CC|RA_ADMISSA|RA_DEPIR|RA_DEMISSA|RA_DEPSF|RA_CHAPA|RA_TNOTRAB|RA_SITFOLH|RA_HRSMES| RA_CATFUNC|RA_CODFUNC|RA_DTFIMCT|RA_HOPARC| "
		_cCmp += "RA_CLAURES|RA_PERCADT|RA_TIPOPGT|RA_FTINSAL|RA_CARGO|RA_DEPTO|RA_CRACHA|RA_REGRA|RA_COMPSAB|RA_SEQTURN|RA_CIC|RA_PIS|RA_RG|RA_RGORG|RA_ORGEMRG|"
		//_cCmp += "RA_NUMCP|RA_SERCP|RA_UFCNH|RA_MSBLQL| RA_TIPAMED|RA_TPASODO|RA_ASODONT|RA_NUMINSC|RA_SERVICO|RA_CODIGO| RA_ADICEDI|RA_XSTMVTO"
		_cCmp += "RA_NUMCP|RA_SERCP|RA_UFCNH|RA_MSBLQL| RA_TIPAMED|RA_TPASODO|RA_ASODONT|RA_NUMINSC|RA_SERVICO|RA_CODIGO| RA_ADICEDI|RA_XSTMVTO |RA_SALARIO"		// Siqueira 03/04/24		
		
		For nI := 1 To Len( aStruFun )
			If !Empty(FWSX3Util():GetFieldType(aStruFun[nI][1])) ; //SX3->( dbSeek( aStruFun[nI][1] ) ) ;     
				.AND. ( AllTRim(GetSx3Cache(aStruFun[nI][1], 'X3_CAMPO')) $ _cCmp)
				aAdd( aStruSRA, aStruFun[nI] )
			EndIf
		Next
		
		TSRA := GetNextAlias() //TSRA := CriaTrab( , .F. )
		oTempTable := FWTemporaryTable():New( TSRA )//dbCreate( TSRA, aStruSRA )
		oTemptable:SetFields( aStruSRA ) //dbUseArea( .T.,, TSRA, TSRA, .T., .F. )
		oTempTable:AddIndex( '01' , { "RA_MAT" } ) //dbCreateInd( TSRA+'1', 'RA_MAT' , &( '{ || '  + 'RA_MAT' + ' }' ) )
		oTempTable:AddIndex( '02' , { "RA_NOME" } ) //dbCreateInd( TSRA+'2', 'RA_NOME' , &( '{ || '  + 'RA_NOME' + ' }' ) )
		oTempTable:Create()//dbClearInd()
		//dbSetIndex( TSRA+'1' + IndexExt() )
		//dbSetIndex( TSRA+'2' + IndexExt() )

		While !( cAliasSra )->( EOF() )

			SRA->( dbGoTo( ( cAliasSra )->SRARECNO ) )

			RecLock( TSRA, .T. )
			aEVal( aStruSRA, { | x, y | ( TSRA )->( FieldPut( y, SRA->( FieldGet( FieldPos( x[1] ) ) ) ) ) } )
			( TSRA )->(MsUnLock())

			( cAliasSra )->( dbSkip() )

		EndDo
	Else
		AVISO("Aviso", "N�o foi encontrado estrutura para o usu�rio logado", { "Ok"}, 1)	
		Return
	EndIF
	aRotina		:= MenuDef(TSRA)
    //Fim MRF	
	
	oDialog := MsDialog():New( aSize[1], aSize[2], aSize[3], aSize[4], , , , , , , , , oMainWnd, .T. )
	oBrowse := FWFormBrowse():New()
	oBrowse:SetOwner( oDialog )   
    oBrowse:SetDataTable(.T.) //Marcos Furtado
	oBrowse:SetTemporary(.T.) 
	oBrowse:SetAlias(TSRA)
    oBrowse:SetSeek(,aSeek)	
   	oBrowse:SetDescription("Solicita��o de Movimenta��es de Pessoal") 
	oBrowse:DisableDetails()

	oBrowse:AddLegend("RA_XSTMVTO == '1'"	,"RED","Aguardando Aprova��o/Efetiva��o")
	oBrowse:AddLegend("Empty(RA_XSTMVTO)"	,"WHITE","Sem solicita��o")
	
	// Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist
 	aRotina	:= MenuDef(TSRA,@oBrowse)

	//Cria bot�es com rotinas
	CreateButton( @oBrowse , aRotina )
	oBrowse:SetUseFilter( .F. )
    
	oBrowse:DisableDetails()
	ADD COLUMN oColumn DATA {|| RA_FILIAL}  TITLE 'Filial' 	        SIZE TamSX3('RA_FILIAL')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_MAT}     TITLE 'Matricula' 	    SIZE TamSX3('RA_MAT')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_NOME}    TITLE 'Nome   ' 	    SIZE TamSX3('RA_NOME  ')[1]  OF oBrowse
	If(RetCodUsr() $ cVeSal)		// Siqueira 03/04/24
		ADD COLUMN oColumn DATA {|| RA_SALARIO} TITLE 'Sal�rio' 	SIZE TamSX3('RA_SALARIO')[1] Picture "@E 999,999.99"  OF oBrowse
	EndIF
	ADD COLUMN oColumn DATA {|| RA_NASC}    TITLE 'Data Nasc.' 	    SIZE TamSX3('RA_NASC')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CC}      TITLE 'Centro Custo' 	SIZE TamSX3('RA_CC  ')[1]  OF oBrowse				
	ADD COLUMN oColumn DATA {|| RA_ADMISSA} TITLE 'Data Admis. ' 	SIZE TamSX3('RA_ADMISSA')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_DEPIR}   TITLE 'Dep. I.R.   ' 	SIZE TamSX3('RA_DEPIR  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_DEMISSA} TITLE 'Dt. Demissao' 	SIZE TamSX3('RA_DEMISSA')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_DEPSF}   TITLE 'Dep.Sal.Fam.' 	SIZE TamSX3('RA_DEPSF  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CHAPA}   TITLE 'Cod. Chapa. ' 	SIZE TamSX3('RA_CHAPA  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_TNOTRAB} TITLE 'Turno Trab. ' 	SIZE TamSX3('RA_TNOTRAB')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_SITFOLH} TITLE 'Sit. Folha  ' 	SIZE TamSX3('RA_SITFOLH')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_HRSMES}  TITLE 'Hrs. Mensais' 	SIZE TamSX3('RA_HRSMES ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CATFUNC} TITLE 'Cat. Func.  ' 	SIZE TamSX3('RA_CATFUNC')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CODFUNC} TITLE 'Cod. Funcao ' 	SIZE TamSX3('RA_CODFUNC')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_DTFIMCT} TITLE 'Dt Term Cont' 	SIZE TamSX3('RA_DTFIMCT')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_HOPARC}  TITLE 'Ct.T.Parcial' 	SIZE TamSX3('RA_HOPARC ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CLAURES} TITLE 'Clau. Assec.' 	SIZE TamSX3('RA_CLAURES')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_PERCADT} TITLE '% Adiantam. ' 	SIZE TamSX3('RA_PERCADT')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_TIPOPGT} TITLE 'Tipo Pgto.  ' 	SIZE TamSX3('RA_TIPOPGT')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_FTINSAL} TITLE 'Multip.Insal' 	SIZE TamSX3('RA_FTINSAL')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CARGO}   TITLE 'Cargo       ' 	SIZE TamSX3('RA_CARGO  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_DEPTO}   TITLE 'Cod. Depto. ' 	SIZE TamSX3('RA_DEPTO  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CRACHA}  TITLE 'Nr. Cracha  ' 	SIZE TamSX3('RA_CRACHA ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_REGRA}   TITLE 'Regra Apont.' 	SIZE TamSX3('RA_REGRA  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_COMPSAB} TITLE 'Comp. S�bado' 	SIZE TamSX3('RA_COMPSAB')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_SEQTURN} TITLE 'Seq.Ini.Turn' 	SIZE TamSX3('RA_SEQTURN')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CIC}     TITLE 'CPF         ' 	SIZE TamSX3('RA_CIC    ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_PIS}     TITLE 'P.I.S.      ' 	SIZE TamSX3('RA_PIS    ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_RG}      TITLE 'R.G.        ' 	SIZE TamSX3('RA_RG     ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_RGORG}   TITLE 'Org.Emissor ' 	SIZE TamSX3('RA_RGORG  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_ORGEMRG} TITLE 'Org Emis RG ' 	SIZE TamSX3('RA_ORGEMRG')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_NUMCP}   TITLE 'Cart.Profis.' 	SIZE TamSX3('RA_NUMCP  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_SERCP}   TITLE 'S�rie Cart. ' 	SIZE TamSX3('RA_SERCP  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_UFCNH}   TITLE 'CNH UF      ' 	SIZE TamSX3('RA_UFCNH  ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_MSBLQL}  TITLE 'Reg.Habilita' 	SIZE TamSX3('RA_MSBLQL ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_TIPAMED} TITLE 'Tipo As. Med' 	SIZE TamSX3('RA_TIPAMED')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_TPASODO} TITLE 'Tp Ass Odon ' 	SIZE TamSX3('RA_TPASODO')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_ASODONT} TITLE 'Cod As Odont' 	SIZE TamSX3('RA_ASODONT')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_NUMINSC} TITLE 'Num Insc Aut' 	SIZE TamSX3('RA_NUMINSC')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_SERVICO} TITLE 'Tp Serv Aut ' 	SIZE TamSX3('RA_SERVICO')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_CODIGO}  TITLE 'Cod Profiss ' 	SIZE TamSX3('RA_CODIGO ')[1]  OF oBrowse
	ADD COLUMN oColumn DATA {|| RA_ADICEDI} TITLE 'Tp.Adi/Cedid' 	SIZE TamSX3('RA_ADICEDI')[1]  OF oBrowse

	oBrowse:Activate()
	oDialog:Activate( ,,,.T.,,, )
	
	oTempTable:Delete()//FErase(TSRA+GetDBExtension())
	//FErase(TSRA+'1'+OrdBagExt())
	//FErase(TSRA+'2'+OrdBagExt())
			
Return

Static Function RetFunc() 

	Local aAux      := {}
	Local aChave    := {}
	Local cConc     := ""
	Local cQuery    := ""
	Local cMy1Alias := "INFTRB"
	Local nCnt      := 0
	
	aAux := U_GetInfMat(.F.)

	cQuery := "SELECT RD4_CHAVE "
	cQuery += "FROM " + RetSqlName("RCX") + " RCX "
	cQuery += "INNER JOIN " + RetSqlName("RD4") + " RD4 "
	cQuery += "ON RD4.D_E_L_E_T_ = ' ' "
	cQuery += "AND RD4_FILIDE = RCX_FILIAL AND RD4_CODIDE = RCX_POSTO "	
	cQuery += "INNER JOIN " + RetSqlName("RDK") + " RDK "
	cQuery += " ON ( RDK.RDK_FILIAL = RD4.RD4_FILIAL AND RDK.RDK_CODIGO = RD4.RD4_CODIGO "
	cQuery += "AND RDK.D_E_L_E_T_ = ' ' ) "
	cQuery += "WHERE RCX.D_E_L_E_T_ = ' ' "
	cQuery += "AND RCX_FILFUN = '" + aAux[1] + "' "
	cQuery += "AND RCX_MATFUN = '" + aAux[2] + "' "
	cQuery += "AND RDK_PADRAO = '1' "
	cQuery += "AND RDK_STATUS = '1' "
	cQuery += "ORDER BY RCX_FILIAL,RCX_FILFUN,RCX_MATFUN,RCX_POSTO "
	
	cQuery := ChangeQuery(cQuery)
	dbUseArea( .T., "TOPCONN", TCGenQry( ,,cQuery ), cMy1Alias, .F., .T. )
	
	While (cMy1Alias)->(!Eof())
		AADD(aChave, (cMy1Alias)->RD4_CHAVE)
		(cMy1Alias)->(DbSkip())
	EndDo
	(cMy1Alias)->(DbCloseArea())
	
	If lBOracle
		cConc := " || "
	Else
		cConc := " + "
	EndIf
	
	cQuery := "SELECT DISTINCT SRA.R_E_C_N_O_ SRARECNO, RA_FILIAL, RA_MAT, RA_NOME, RA_NASC, RA_CC, RA_ADMISSA, RA_DEPIR, RA_DEMISSA, RA_DEPSF, RA_CHAPA, "
	cQuery += "RA_TNOTRAB, RA_SITFOLH, RA_HRSMES, RA_CATFUNC, RA_CODFUNC, RA_DTFIMCT, RA_HOPARC, RA_CLAURES, RA_PERCADT, RA_TIPOPGT, "
	cQuery += "RA_FTINSAL, RA_CARGO, RA_DEPTO, RA_CRACHA, RA_REGRA, RA_COMPSAB, RA_SEQTURN, RA_CIC, RA_PIS, RA_RG, "
	cQuery += "RA_RGORG, RA_ORGEMRG, RA_NUMCP, RA_SERCP, RA_UFCNH, RA_MSBLQL, RA_TIPAMED, RA_TPASODO, RA_ASODONT, RA_NUMINSC, "
	cQuery += "RA_SERVICO, RA_CODIGO, RA_ADICEDI, RA_XSTMVTO "
	cQuery += "FROM " + RetSqlName("RD4") + " RD4 "
	cQuery += "INNER JOIN " + RetSqlName("RDK") + " RDK "
	cQuery += " ON ( RDK.RDK_FILIAL = RD4.RD4_FILIAL AND RDK.RDK_CODIGO = RD4.RD4_CODIGO "
	cQuery += "AND RDK.D_E_L_E_T_ = ' ' ) "
	cQuery += "INNER JOIN " + RetSqlName("RCX") + " RCX "
	cQuery += "  ON RCX.D_E_L_E_T_ = ' ' "
	cQuery += "  AND RCX_FILIAL = RD4_FILIDE "
	cQuery += "  AND RCX_POSTO = RD4_CODIDE "
	cQuery += "INNER JOIN " + RetSqlName("SRA") + " SRA "
	cQuery += "  ON SRA.D_E_L_E_T_ = ' ' "
	cQuery += "  AND SRA.RA_MAT = RCX.RCX_MATFUN "
	cQuery += "  AND SRA.RA_FILIAL = RCX.RCX_FILFUN "
	cQuery += "WHERE RD4.D_E_L_E_T_ = ' ' "
	cQuery += "AND RD4_CODIGO IN (SELECT RD4_CODIGO "
	cQuery += "FROM " + RetSqlName("RCX") + " RCX "
	cQuery += "INNER JOIN " + RetSqlName("RD4") + " RD4 "
	cQuery += "  ON RD4.D_E_L_E_T_ = ' ' "
	cQuery += "  AND RD4_FILIDE = RCX_FILIAL "
	cQuery += "  AND RD4_CODIDE = RCX_POSTO "
	cQuery += "WHERE RCX.D_E_L_E_T_ = ' ' "
	cQuery += "AND RDK_PADRAO = '1' "
	cQuery += "AND RDK_STATUS = '1' "
	cQuery += "AND RCX_FILFUN = '" + aAux[1] + "' "
	cQuery += "AND RCX_MATFUN = '" + aAux[2] + "') "
	If Len(aChave) > 0 
		cQuery += " AND ("
		For nCnt := 1 To Len(aChave)
			cQuery += "( RD4_CHAVE LIKE LTRIM(RTRIM( "
			cQuery += " '"+ aChave[nCnt] + "' "
			cQuery += ")) " + cConc + " '%' )"
			If nCnt < Len(aChave)
				cQuery += " OR "
			EndIf
		Next
		cQuery += ") "
	EndIf
	cQuery += " AND RCX_MATFUN <> '"+aAux[2]+"' "	
	cQuery += "ORDER BY RA_FILIAL, RA_MAT "
	
Return cQuery

/*{Protheus.doc} CreateButton
Cria��o dos bot�es no browse
@type Static function
@author Cris
@since 20/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${_aRotina}, ${Rotinas do menu}
*/
Static Function CreateButton( oBrowse , aRotina )
	Local cTitle	:= ""
	Local cRot		:= ""
	Local nOpc		:= 0
	Local nFunc 	:= 0
	
	For nFunc := 1 To Len( aRotina )
		cTitle	:= aRotina[nFunc][1]
		cRot	:= aRotina[nFunc][2]
		nOcp	:= aRotina[nFunc][4]
		oBrowse:AddButton( cTitle, cRot ,, nOcp ) //"Confirmar"
	Next nFunc
Return Nil

/*{Protheus.doc} MenuDef
Monta o menu especifico do modelo
@type Static function
@author Cris
@since 20/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${_aRotina}, ${Rotinas do menu}
*/
Static Function MenuDef(cAliasSra,oBrowse)
	
	Local _aRotina := {}
	Local aMatInc  := {}
	Local aAreaSRA := {}
	
	Default cAliasSra	:= "SRA"
	//	ADD OPTION _aRotina TITLE "Incluir" ACTION "U_F0500413()" OPERATION 3 ACCESS 0
	//	ADD OPTION _aRotina TITLE "Visualizar Solicita��o" ACTION "U_F0500413(" + (TSRA)->RA_FILIAL + "," + (TSRA)->RA_MAT + ")" OPERATION 3 ACCESS 0

	// ADD OPTION _aRotina TITLE "Incluir" ACTION "U_X0500401(@oBrowse)" /* "U_F0500413()" */ OPERATION 3 ACCESS 0 // Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist
	// ADD OPTION _aRotina TITLE "Visualizar Solicita��o" ACTION "U_F0500412('" + cAliasSra + "')" OPERATION 1 ACCESS 0
	// ADD OPTION _aRotina TITLE "Cancelar Solicita��o" ACTION "U_F0500425('" + cAliasSra + "')" OPERATION 6 ACCESS 0

	Aadd(aRot , {"Incluir"    , "U_X0500401(@oBrowse)"        , 0, 3})
	Aadd(aRot , {"Visualizar Solicita��o"    , "U_F0500412('" + cAliasSra + "')"        , 0, 1})
	Aadd(aRot , {"Cancelar Solicita��o"    , "U_F0500425('" + cAliasSra + "')"        , 0, 6})
	
Return _aRotina

/*{Protheus.doc} MODELDEF
trecho para definir as tabelas e regras do modelo
@type Static function
@author Cris
@since 20/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oModel}, ${modelo total com as tabelas e regras}
*/
Static Function  ModelDef()
	
	Local oStrMov	:= MDStrCab()
	Local oStrSal	:= MDStrSal()
	Local oStrCar	:= MDStrCar()
	Local oStrHor	:= MDStrHor()
	Local oStrTur	:= MDStrTur()
	Local oStrTrf	:= MDStrTrf()
	Local oStrTSal	:= MDStrRB6()
	Local oStrPnal	:= MDStrPrp()
	Local bPostMod	:= {||               GF00504VL() }//Valida se foi informado alguma altera��o e se as informa�oes  s�o validas. // gus
//	Local bPostMod	:= {|| GFSVLSALP() ,  F00504VL() }//Valida se foi informado alguma altera��o e se as informa�oes  s�o validas. // gus
	Local oModel
	Local bPreValid := {|| .T.         } //{|| SetStatic()}
	
	//Descri��o da Filial Para
	aAux := FwStruTrigger ( 'FILIPROP', 'TMP_N_F_D', 'U_F0500411()' , .F. )
	oStrTrf:AddTrigger( aAux[1] , aAux[2] , aAux[3], aAux[4])
	
	aAux := FwStruTrigger( 'FILIPROP', 'CCUSTOPROP', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( 'FILIPROP', 'TMP_D_CC_D', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( 'FILIPROP', 'DEPTOPROP', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( 'FILIPROP', 'TMP_D_DEPD', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
		
	If cTipOrgA ==  '1'
		aAux := FwStruTrigger( 'FILIPROP', 'POSTOPROP', '""',.F.)
		oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
		
		aAux := FwStruTrigger( 'FILIPROP', 'DFUNCPROP', '""',.F.)
		oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
			
		//Descri��o do posto
		aAux := FwStruTrigger ( 'POSTOPROP', 'DFUNCPROP', 'U_FSATUDESC()' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
		oStrTrf:AddTrigger( aAux[1] , aAux[2] , aAux[3], aAux[4])	
	EndIf
	
	aAux := FwStruTrigger( 'FILIPROP', 'CLVLPROP', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	aAux := FwStruTrigger( 'FILIPROP', 'ITEMPROP', '""',.F.)
	oStrTrf:AddTrigger( aAux[1], aAux[2], aAux[3], aAux[4])
	
	oModel	:= MPFormModel():New("M0500401", bPreValid,bPostMod, {|oModel| PrepGrv(oModel)}, NIL)
	
	oModel:AddFields("F0500401"		, ,oStrMov)
	oModel:AddFields( 'SALDETAIL'	, 'F0500401', oStrSal)
	oModel:AddGrid( 'RB6DETAIL'		, 'SALDETAIL', oStrTSal)
	oModel:AddGrid( 'TMPDETAIL'		, 'SALDETAIL', oStrPnal)
	oModel:AddFields( 'CARDETAIL'	, 'F0500401', oStrCar)
	oModel:AddFields( 'HORDETAIL'	, 'F0500401', oStrHor)
	oModel:AddFields( 'TURDETAIL'	, 'F0500401', oStrTur)
	oModel:AddFields( 'TRFDETAIL'	, 'F0500401', oStrTrf)
	
	oModel:GetModel("F0500401"):SetDescription('Solicita��o de Movimenta��es de Pessoal')
	oModel:GetModel( 'SALDETAIL' ):SetDescription( 'Altera��o Salarial')
	oModel:GetModel( 'CARDETAIL' ):SetDescription( 'Altera��o de Cargo')
	oModel:GetModel( 'HORDETAIL' ):SetDescription( 'Altera��o de Carga Hor�ria')
	oModel:GetModel( 'TURDETAIL' ):SetDescription( 'Altera��o de Troca de Turno')
	oModel:GetModel( 'TRFDETAIL' ):SetDescription( 'Altera��o->Transfer�ncia')
	oModel:GetModel('RB6DETAIL'):SetOptional( .T. )
	oModel:GetModel('RB6DETAIL'):SetOnlyQuery(.T.)//Indica que o modelo � somente consulta e nao grav�vel
	oModel:GetModel('RB6DETAIL'):SetNoDeleteLine(.T.)
	oModel:GetModel('TMPDETAIL'):SetOptional( .T. )
	oModel:GetModel('TMPDETAIL'):SetOnlyQuery(.T.)//Indica que o modelo � somente consulta e nao grav�vel
	oModel:GetModel('TMPDETAIL'):SetNoDeleteLine(.T.)
	
	oModel:SetPrimaryKey({})
	oModel:GetModel('SALDETAIL'):SetPrimaryKey({})
	oModel:GetModel('CARDETAIL'):SetPrimaryKey({})
	oModel:GetModel('HORDETAIL'):SetPrimaryKey({})
	oModel:GetModel('TURDETAIL'):SetPrimaryKey({})
	oModel:GetModel('TRFDETAIL'):SetPrimaryKey({})
	
	//Verifica se j� existe solicita��o para o funcion�rio posicionado e se a mesma j� foi atendida
	oModel:SetVldActivate({|| FS05EXIS() .AND. VldPermis() .And. SetStatic()})//SRA->RA_FILIAL,SRA->RA_MAT
	
Return oModel

/*{Protheus.doc} MDStrCab
Monta os campos da estrutura cabe�alho
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo do cabe�alho}
*/
Static Function MDStrCab()
	
	Local oStruct := FWFormModelStruct():New()
	
	oStruct:AddTable("CABSOL", {" "}, "Solicita��o")
	
	oStruct:AddField(Alltrim(GetSx3Cache("RH3_MAT","X3_TITULO"))        ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RH3_MAT","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "RH3_MAT"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RH3_MAT","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RH3_MAT")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RH3_MAT")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .T.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RH3_NOME","X3_TITULO"))       ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RH3_NOME","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "RH3_NOME"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RH3_NOME","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RH3_NOME")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RH3_NOME")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .T.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("M�s/Ano Solicita��o"						        ,;	// 	[01]  C   Titulo do campo
	                 "M�s/Ano Solicita��o"								,;	// 	[02]  C   ToolTip do campo
	                 "RH3DTSOLI"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 7													,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .T.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:SetProperty('RH3_MAT', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD,'SRA->RA_MAT'))
	oStruct:SetProperty('RH3_NOME', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD,'SRA->RA_NOME'))
	oStruct:SetProperty('RH3DTSOLI', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD,'StrZero(Month(MsDate()),2)+"/"+StrZero(Year(MsDate()),4)'))
	
Return oStruct

/*{Protheus.doc} MDStrSal
Monta o sub-modelo da Altera��o Salarial
@type Static function
@author Cris
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${modelo da aba Altera��o Salarial}
*/
Static Function MDStrSal()
	
	Local oStruct  := FWFormModelStruct():New()
	Local aGatilho := {}
	
	oStruct:AddTable("ALTSAL", {" "}, "Solicita��o de Altera��o Salarial")
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_CARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_CARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "TMP_CARGO"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_CARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_CARGO")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_CARGO")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_CARGO}									,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_DCARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_DCARGO","X3_DESCRIC"))	    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_FUNC"									    ,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_DCARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_DCARGO")[1]							    ,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_DCARGO")[2]                             ,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| POSICIONE("SQ3",1,FwxFilial("SQ3")+SRA->RA_CARGO,"Q3_DESCSUM")},;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField('Sal�rio Atual'								    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_SALARIO","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_SALATU"								        ,;	// 	[03]  C   Id do Field
	                 "N"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_SALARIO")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_SALARIO")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_SALARIO}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TABELA","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABELA","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "TMP_TABELA"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TABELA","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TABELA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TABELA")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_TABELA}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TABNIVE","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABNIVE","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_NIVELT"									    ,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TABNIVE","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TABNIVE")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TABNIVE")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_TABNIVE}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 .T.												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TABFAIX","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABFAIX","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_FAIXAT"									    ,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TABFAIX","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TABFAIX")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TABFAIX")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_TABFAIX}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField('Sal�rio Proposto'								    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_SALARIO","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "SALARIOPROP"										,;	// 	[03]  C   Id do Field
	                 "N"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_SALARIO")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_SALARIO")[2]							,;	// 	[06]  N   Decimal do campo
			         {|| FSVLSALP(),MDGatilho(2)}    					,;	// 	[07]  B   Code-block de valida��o do campo // gus
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField('Sal�rio Hora'								        ,;	// 	[01]  C   Titulo do campo
	                 'Sal�rio Hora'		                                ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_SALHR"										,;	// 	[03]  C   Id do Field
	                 "N"												,;	// 	[04]  C   Tipo do campo
	                 15 /*TamSX3("RA_SALARIO")[1]*/						,;	// 	[05]  N   Tamanho do campo
	                 9  /*TamSX3("RA_SALARIO")[2]*/						,;	// 	[06]  N   Decimal do campo
	                 {|| .T.}									        ,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| MdSalHr()}										,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	 
	oStruct:AddField('Valor Reajuste'								    ,;	// 	[01]  C   Titulo do campo
	                 'Valor Reajuste'									,;	// 	[02]  C   ToolTip do campo
	                 "TMP_VLSALA"										,;	// 	[03]  C   Id do Field
	                 "N"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_SALARIO")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_SALARIO")[2]							,;	// 	[06]  N   Decimal do campo
			         {|| MDGatilho(3)}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField('Percentual do Reajuste'						    ,;	// 	[01]  C   Titulo do campo
	                 'Percentual do Reajuste'							,;	// 	[02]  C   ToolTip do campo
	                 "TMP_PERCSA"										,;	// 	[03]  C   Id do Field
	                 "N"												,;	// 	[04]  C   Tipo do campo
	                 6													,;	// 	[05]  N   Tamanho do campo
	                 2													,;	// 	[06]  N   Decimal do campo
			         {|| MDGatilho(4)}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TIPOALT","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TIPOALT","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "MOTALTSAL"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TIPOALT","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TIPOALT")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 {|| MOTALTSL()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 NIL												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri��o do Motivo Salarial"					    ,;	// 	[01]  C   Titulo do campo
	                 "Descri��o do Motivo Salarial"						,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_MOT"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 30													,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 NIL												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	                 
	oStruct:AddField("M�rito?"      					                ,;	// 	[01]  C   Titulo do campo
	                 "M�rito?"              						    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_ESCL"										    ,;	// 	[03]  C   Id do Field
	                 "C"											    ,;	// 	[04]  C   Tipo do campo
	                 1												    ,;	// 	[05]  N   Tamanho do campo
	                 0												    ,;	// 	[06]  N   Decimal do campo
	                 NIL											    ,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL     										    ,;	// 	[08]  B   Code-block de valida��o When do campo
	              	 {"1=SIM","2=NAO"}								    ,;	//	[09]  A   Lista de valores permitido do campo
	                 NIL											    ,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| "2=NAO" }									    ,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL											    ,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.											    ,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.											    )	// 	[14]  L   Indica se o campo � virtual

	//Descri��o do tipo de altera��o
	aGatilho := FwStruTrigger ( 'MOTALTSAL', 'TMP_D_MOT', 'POSICIONE("SX5",1,FwxFilial("SX5")+"41"+FwFldGet("MOTALTSAL"),"X5_DESCRI")',.F.,,,, )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
Return oStruct

/*{Protheus.doc} $MOTALTSL
Valida��o do motivo de altera��o da aba Altera��o Salarial, se foi informado
@type Static function
@author Cris
@since 01/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValTp}, ${.T. v�lido e .F. n�o v�lido}
*/
Static Function MOTALTSL()
	
	Local oModAtu :=	FWModelActive()
	Local cMotivo :=	oModAtu:GetModel("SALDETAIL"):GEtValue("MOTALTSAL")
	Local lValTp  := .T.
	
	if oModAtu:GetModel("SALDETAIL"):GEtValue("SALARIOPROP") <> 0 .AND. Empty(cMotivo)
		
		Help("",1, "1XX", "Valida��o de Motivo(MOTALTSL_01)", "Na Altera��o salarial � obrigat�rio informar o motivo da mesma!" , 3, 0)
		lValTp	:= .F.
		
	EndIf
	
	if !Empty(cMotivo)
		
		ExistMot(cMotivo,@lValTp)
		
	EndIf
	
Return lValTp

/*{Protheus.doc} ExistMot
Valida se o motivo informado � valido
@type function
@author Cris
@since 21/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@param cMotivo, character, (Codigo do motivo informado manualmente)
@param lValTp, ${l�gico}, (Retorna se o motivo  informado � valido ou n�o)
@return ${return}, ${return_description}
*/
Static Function ExistMot(cMotivo,lValTp)
	
	Local aAreaSX5 := SX5->(GetArea())
	
	dbSelectArea("SX5")
	SX5->(dbSetOrder(1))
	If !SX5->(dbSeek(FwxFilial("SX5")+"41"+cMotivo))
		
		Help("",1, "Help", "Valida��o de Motivo(ExistMot_01)", "C�digo de Motivo inv�lido. Informe um c�digo de motivo existente!" , 3, 0)
		lValTp := .F.
		
	Else
		
		lValTp := .T.
		
	EndIf
	
	RestArea(aAreaSX5)
	
Return

/*{Protheus.doc} MOTALTCG
Valida se o motivo foi informado na altera��o de cargo.
@type function
@author Cris
@since 03/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValTp}, ${.T. motivo informado v�lido .F. motivo informado n�o v�lido}
*/
Static Function MOTALTCG()
	
	Local oModAtu :=	FWModelActive()
	Local cMotivo :=	oModAtu:GetModel("CARDETAIL"):GetValue("MALTCARSAL")
	Local lValTp  := .T.
	
	If !Empty(oModAtu:GetModel("CARDETAIL"):GetValue("CARGOPROP")) .AND. Empty(cMotivo)
		
		Help("",1, "Help", "Valida��o de Motivo(MOTALTCG_01)", "Na Altera��o de cargo � obrigat�rio informar o motivo do mesmo!" , 3, 0)
		
		lValTp	:= .F.
		
	EndIf
	
	If !Empty(cMotivo)
		
		ExistMot(cMotivo,@lValTp)
		
	EndIf
	
Return lValTp

/*{Protheus.doc} MDStrCar
Monta o modelo da aba Altera��o de Cargo
@type Static function
@author Cris
@since 03/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${sub-modelo da aba Altera��o de Cargo}
*/
Static Function MDStrCar()
	
	Local oStruct := FWFormModelStruct():New()
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_CARGO","X3_TITULO"))       ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_CARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "TMP_CARGO"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_CARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_CARGO")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_CARGO")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_CARGO}									,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_DCARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_DCARGO","X3_DESCRIC"))	    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_FUNC"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_DCARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_DCARGO")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_DCARGO")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| POSICIONE("SQ3",1,FwxFilial("SQ3")+SRA->RA_CARGO,"Q3_DESCSUM")},;//	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_CARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_CARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "CARGOPROP"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_CARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_CARGO")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_CARGO")[2]								,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLCARP()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .t.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_DCARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_DCARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_F_PP"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_DCARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_DCARGO")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_DCARGO")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TIPOALT","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TIPOALT","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "MALTCARSAL"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TIPOALT","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TIPOALT")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TIPOALT")[2]							,;	// 	[06]  N   Decimal do campo
	                 {|| MOTALTCG()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .t.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri��o do Motivo Salarial"					    ,;	// 	[01]  C   Titulo do campo
	                 "Descri��o do Motivo Salarial"						,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_MOTC"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 30													,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 NIL												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	//Descri��o do Cargo
	aGatilho := FwStruTrigger ( 'CARGOPROP', 'TMP_D_F_PP', 'IIF(!Empty(FwFldGet("CARGOPROP")),U_F0500408("SQ3",FwFldGet("CARGOPROP"),"Q3_DESCSUM"),"")', .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//Descri��o do tipo de altera��o
	aGatilho := FwStruTrigger ( 'MALTCARSAL', 'TMP_D_MOTC', 'POSICIONE("SX5",1,FwxFilial("SX5")+"41"+MALTCARSAL,"X5_DESCRI")', .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
Return oStruct

/*{Protheus.doc} $MDStrHor
Modelo da aba Carga Hor�ria
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${modelo da aba Carga hor�ria}
*/
Static Function MDStrHor()
	
	Local oStruct  := FWFormModelStruct():New()
	Local aGatilho := {}
	
	oStruct:AddTable("CARHR", {" "}, "Carga Hor�ria")
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSMES","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSMES","X3_DESCRIC"))     ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_H_M_AT"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSMES","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSMES")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSMES")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_HRSMES }								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSEMAN","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSEMAN","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_H_S_AT"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSEMAN","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSEMAN")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSEMAN")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_HRSEMAN}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSDIA","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSDIA","X3_DESCRIC"))	    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_H_D_AT"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSDIA","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSDIA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSDIA")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_HRSDIA}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSMES","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSMES","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "HMESPROP"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSMES","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSMES")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSMES")[2]								,;	// 	[06]  N   Decimal do campo
			         {|| MDGatilho(1) , FSVLHORP(1) }                   ,;  //{|| FSVLHORP(1), MDGatilho(1)}						,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSEMAN","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSEMAN","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "HSEMPROP"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSEMAN","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSEMAN")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSEMAN")[2]							,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLHORP()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_HRSDIA","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_HRSDIA","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "HDIAPROP"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_HRSDIA","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_HRSDIA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_HRSDIA")[2]								,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLHORP()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	//Horas M�s
	aGatilho := FwStruTrigger ( 'HMESPROP', 'HSEMPROP', 'IIF(FwFldGet("HMESPROP") <> 0 , FwFldGet("HMESPROP")/5,0)' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	aGatilho := FwStruTrigger ( 'HMESPROP', 'HDIAPROP', 'IIF(FwFldGet("HMESPROP")<> 0, FwFldGet("HMESPROP")/30,0) ' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//Horas Semanas
	aGatilho := FwStruTrigger ( 'HSEMPROP', 'HMESPROP', 'IIF(FwFldGet("HSEMPROP") <> 0, FwFldGet("HSEMPROP")*5,0) ' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//Horas Dias
	aGatilho := FwStruTrigger ( 'HDIAPROP', 'HMESPROP', 'IIF(FwFldGet("HDIAPROP")<> 0, FwFldGet("HDIAPROP")*30,0) ' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
Return oStruct

/*{Protheus.doc} MDGatilho
Gatilho do Modelo
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${modelo da aba Carga hor�ria}
*/
Static Function MDGatilho(nMyOpcao)
	
	Local oModAtu    :=	FWModelActive()
	
	Default nMyOpcao := 1
	
	//Alteracao de Carga Horaria
	IF oModAtu:GetModel("HORDETAIL"):GetValue("HMESPROP") <> 0 .And. nMyOpcao = 1
		oModAtu:GetModel("SALDETAIL"):SetValue( "SALARIOPROP",Round((oModAtu:GetModel("HORDETAIL"):GetValue("HMESPROP")*oModAtu:GetModel("SALDETAIL"):GetValue("TMP_SALHR")),2) )
		oModAtu:GetModel("SALDETAIL"):SetValue( "TMP_VLSALA", Round((oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP")-SRA->RA_SALARIO),2) )
		oModAtu:GetModel("SALDETAIL"):SetValue( "TMP_PERCSA", Round(((oModAtu:GetModel("SALDETAIL"):GetValue("TMP_VLSALA")/SRA->RA_SALARIO)*100),2) )
	EndIf
	
	//Valor do Salario Proposto
	IF oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP") > 0 .And. nMyOpcao = 2
		oModAtu:GetModel("SALDETAIL"):LoadValue( "TMP_VLSALA", oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP")-SRA->RA_SALARIO )
		oModAtu:GetModel("SALDETAIL"):LoadValue( "TMP_PERCSA", Round(((oModAtu:GetModel("SALDETAIL"):GetValue("TMP_VLSALA")/SRA->RA_SALARIO)*100),2) )
	EndIf
	
	//Valor Reajuste
	// ticket n� 5594755 - 415966 - Paulo Dias - ajuste no gatilho.
	IF oModAtu:GetModel("SALDETAIL"):GetValue("TMP_VLSALA") > 0 .And. nMyOpcao = 3 //.And. oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP") = 0
		oModAtu:GetModel("SALDETAIL"):LoadValue( "SALARIOPROP", SRA->RA_SALARIO+oModAtu:GetModel("SALDETAIL"):GetValue("TMP_VLSALA") )
		oModAtu:GetModel("SALDETAIL"):LoadValue( "TMP_PERCSA", Round(((oModAtu:GetModel("SALDETAIL"):GetValue("TMP_VLSALA")/SRA->RA_SALARIO)*100),2) )
	EndIf
	
	//Percentual do Reajuste
	// ticket n� 5594755 - 415966 - Paulo Dias - ajuste no gatilho.
	IF oModAtu:GetModel("SALDETAIL"):GetValue("TMP_PERCSA") > 0 .And. nMyOpcao = 4 //.And. oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP") = 0
		oModAtu:GetModel("SALDETAIL"):LoadValue( "SALARIOPROP", SRA->RA_SALARIO+Round((SRA->RA_SALARIO*(oModAtu:GetModel("SALDETAIL"):GetValue("TMP_PERCSA")/100)),2) )
		oModAtu:GetModel("SALDETAIL"):LoadValue( "TMP_VLSALA", oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP")-SRA->RA_SALARIO )
	EndIf

	
Return(.T.)

/*{Protheus.doc} MDStrTur
Monta o Sub-Modelo Altera��o de Turno
@type function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo da Aba Altera��o de Turno}
*/
Static Function MDStrTur()
	
	Local oStruct  := FWFormModelStruct():New()
	Local aGatilho := {}
	
	oStruct:AddTable("TURNO", {" "}, "Turno de Trabalho")
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TNOTRAB","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TNOTRAB","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_TURNAT"									    ,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TNOTRAB","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TNOTRAB")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TNOTRAB")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_TNOTRAB}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri�ao do Turno"					            ,;	// 	[01]  C   Titulo do campo
	                 "Descri�ao do Turno"							    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_TURN"									    ,;	// 	[03]  C   Id do Field
	                 "C"											    ,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_DESCTUR")[1]						    ,;	// 	[05]  N   Tamanho do campo
	                 0												    ,;	// 	[06]  N   Decimal do campo
	                 NIL											    ,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}										    ,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL											    ,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.											    ,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| POSICIONE("SR6",1,FwxFilial("SR6")+SRA->RA_TNOTRAB,"R6_DESC")},;//	[11]  B   Code-block de inicializacao do campo
	                 NIL											    ,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.											    ,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.											    )	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_SEQTURN","X3_TITULO"))     ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_SEQTURN","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TMP_S_TURN"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_SEQTURN","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_SEQTURN")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_SEQTURN")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_SEQTURN}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_REGRA","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_REGRA","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "TMP_REGRA"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_REGRA","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_REGRA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_REGRA")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_REGRA}									,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_TNOTRAB","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TNOTRAB","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "TURNOPROP"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_TNOTRAB","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_TNOTRAB")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_TNOTRAB")[2]							,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLTURP()}									,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri�ao do Turno"						        ,;	// 	[01]  C   Titulo do campo
	                 "Descri�ao do Turno"							    ,;	// 	[02]  C   ToolTip do campo
	                 "TMP_DESCTU"									    ,;	// 	[03]  C   Id do Field
	                 "C"											    ,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_DESCTUR")[1]						    ,;	// 	[05]  N   Tamanho do campo
	                 0												    ,;	// 	[06]  N   Decimal do campo
	                 NIL											   	,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL											    ,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL											    ,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.											    ,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil											    ,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL											    ,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.											    ,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.											    )	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_SEQTURN","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_SEQTURN","X3_DESCRIC"))	,;	// 	[02]  C   ToolTip do campo
	                 "STURPROP"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_SEQTURN","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_SEQTURN")[1]							,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_SEQTURN")[2]							,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField(Alltrim(GetSx3Cache("RA_REGRA","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_REGRA","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "REGRAPROP"										,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RA_REGRA","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RA_REGRA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RA_REGRA")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	//Descri��o do Turno  Proposta
	aGatilho := FwStruTrigger ( 'TURNOPROP', 'TMP_DESCTU', 'IIF(!Empty(FwFldGet("TURNOPROP")),U_F0500408("SR6",FwFldGet("TURNOPROP"),"R6_DESC")," ") ' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	aGatilho := FwStruTrigger ( 'TURNOPROP', 'STURPROP', 'IIF(!Empty(FwFldGet("TURNOPROP")),Posicione("SPJ",1,xFilial("SPJ")+FwFldGet("TURNOPROP")+"01","PJ_SEMANA")," ")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	aGatilho := FwStruTrigger ( 'TURNOPROP', 'REGRAPROP', 'IIF(!Empty(FwFldGet("TURNOPROP")),Posicione("SPA",1,xFilial("SPA")+"01","PA_CODIGO")," ")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
Return oStruct

/*{Protheus.doc} MDStrTrf
Monta o Sub-modelo da Transfer�ncia
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Retorna as caracteristicas e regras do sub-modelo da aba Tansfer�ncia}
*/
Static Function MDStrTrf()
	
	Local oStruct := FWFormModelStruct():New()
	
	oStruct:AddTable("TRF", {" "}, "Transfer�ncia")
	
	oStruct:AddField("Filial"									        ,;	// 	[01]  C   Titulo do campo
	                 "Filial"											,;	// 	[02]  C   ToolTip do campo
	                 "TMP_FILIAL"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RH4_FILIAL")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0					 								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_FILIAL}								,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Nome da Filial"							        ,;	// 	[01]  C   Titulo do campo
	                 "Nome da Filial"									,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_FILI"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RE_DFILORI")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| FWFilialName(,SRA->RA_FILIAL)}					,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Centro de Custo"							        ,;	// 	[01]  C   Titulo do campo
	                 "Centro de Custo"									,;	// 	[02]  C   ToolTip do campo
	                 "TMP_CCATU"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RE_CCD")[1]								,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_CC}									,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri��o do Centro de Custo"				        ,;	// 	[01]  C   Titulo do campo
	                 "Descri�ao do Centro de Custo"						,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_CCAT"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("CTT_DESC01")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| fDesc("CTT",SRA->RA_CC,"CTT_DESC01")}			,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Departamento"								        ,;	// 	[01]  C   Titulo do campo
	                 "Departamento"										,;	// 	[02]  C   ToolTip do campo
	                 "TMP_DEPTOA"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RE_DEPTOD")[1]								,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| SRA->RA_DEPTO}									,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Nome do Departamento"						        ,;	// 	[01]  C   Titulo do campo
	                 "Nome do Departamento"								,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_DEPT"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("QB_DESCRIC")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 {|| fDesc("SQB",SRA->RA_DEPTO,"QB_DESCRIC")}		,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	//SIGAORG como posto
	if cTipOrgA == '1'
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_POSTO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_POSTO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "TMP_POSTO"										,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_POSTO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_POSTO")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio  
		                 {|| SRA->RA_POSTO}									,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_DCARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_DCARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "TMP_DFUNCAO"										,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_DCARGO","X3_TIPO")				    ,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_DCARGO")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 {|| POSICIONE("SQ3",1,FwxFilial("SQ3")+SRA->RA_CARGO,"Q3_DESCSUM")},;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	EndIf
	
	//SIGACTB por item, classe e valor
	if cClasVlA == '1'
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_CLVL","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_CLVL","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "TMP_CLVL"											,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_CLVL","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_CLVL")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 {|| SRA->RA_CLVL}									,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_ITEM","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_ITEM","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "TMP_ITEM"											,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_ITEM","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_ITEM")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 {|| SRA->RA_ITEM}									,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
	EndIf
	
	oStruct:AddField("Filial"									        ,;	// 	[01]  C   Titulo do campo
	                 "Filial"											,;	// 	[02]  C   ToolTip do campo
	                 "FILIPROP"											,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RH4_FILIAL")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0					 								,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLTRFP("FILIAL")}							,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Nome da Filial"							        ,;	// 	[01]  C   Titulo do campo
	                 "Nome da Filial"									,;	// 	[02]  C   ToolTip do campo
	                 "TMP_N_F_D"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 50	                        						,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL         									    ,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Centro de Custo"							        ,;	// 	[01]  C   Titulo do campo
	                 "Centro de Custo"									,;	// 	[02]  C   ToolTip do campo
	                 "CCUSTOPROP"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RE_CCD")[1]								,;	// 	[05]  N   Tamanho do campo
       	             0													,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLTRFP("CENTROC")}							,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Descri��o do Centro de Custo"				        ,;	// 	[01]  C   Titulo do campo
	                 "Descri�ao do Centro de Custo"						,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_CC_D"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("CTT_DESC01")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Departamento"								        ,;	// 	[01]  C   Titulo do campo
	                 "Departamento"										,;	// 	[02]  C   ToolTip do campo
	                 "DEPTOPROP"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RE_DEPTOD")[1]								,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 {|| FSVLTRFP("DEPTO")}								,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Nome do Departamento"						        ,;	// 	[01]  C   Titulo do campo
	                 "Nome do Departamento"								,;	// 	[02]  C   ToolTip do campo
	                 "TMP_D_DEPD"										,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("QB_DESCRIC")[1]							,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
	//SIGAORG como posto
	if cTipOrgA == '1'
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_POSTO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_POSTO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "POSTOPROP"										,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_POSTO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_POSTO")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 {|| FSVLTRFP("POSTOD")}							,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_DCARGO","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_DCARGO","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "DFUNCPROP"										,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_DCARGO","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_DCARGO")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 NIL												,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 {|| IIF(!Empty(FwFldGet("POSTOPROP")),POSICIONE("SQ3",1,FwxFilial("SQ3")+FwFldGet("POSTOPROP"),"Q3_DESCSUM"),"")}	,;  //	[11]  B   Code-block de inicializacao do campo - 7780516 - Thais Paiva 
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
	EndIf
	
	//SIGACTB por item, classe e valor
	if cClasVlA == '1'
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_CLVL","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_CLVL","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "CLVLPROP"											,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_CLVL","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_CLVL")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
		
		oStruct:AddField(Alltrim(GetSx3Cache("RA_ITEM","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
		                 Alltrim(GetSx3Cache("RA_ITEM","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
		                 "ITEMPROP"											,;	// 	[03]  C   Id do Field
		                 GetSx3Cache("RA_ITEM","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
		                 TamSX3("RA_ITEM")[1]								,;	// 	[05]  N   Tamanho do campo
		                 0													,;	// 	[06]  N   Decimal do campo
		                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
		                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
		                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
		                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
		                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
		                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
		                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
		                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	EndIf
	
	//-Se preencher CC, preenche Departamento com o mesmo codigo pois � "1 pra 1"
	aGatilho := FwStruTrigger ( 'CCUSTOPROP', 'DEPTOPROP', 'iif(!Empty(FwFldGet("CCUSTOPROP")),POSICIONE("SQB",4,xFilial("SQB")+FwFldGet("CCUSTOPROP"),"QB_DEPTO"),"")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//-Se preencher Departamento, preenche CC com o mesmo codigo pois � "1 pra 1"
	aGatilho := FwStruTrigger ( 'DEPTOPROP', 'CCUSTOPROP', 'iif(!Empty(FwFldGet("DEPTOPROP")),POSICIONE("SQB",1,xFilial("SQB")+FwFldGet("DEPTOPROP"),"QB_CC"),"")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//Descri��o do departamento Para
	aGatilho := FwStruTrigger ( 'DEPTOPROP', 'TMP_D_DEPD', 'iif(!Empty(FwFldGet("DEPTOPROP")),U_F0500408("SQB",FwFldGet("DEPTOPROP"),"QB_DESCRIC")," ")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
	//Descri��o do centro de custo para
	aGatilho := FwStruTrigger ( 'CCUSTOPROP', 'TMP_D_CC_D', 'iif(!Empty(FwFldGet("CCUSTOPROP")),U_F0500408("CTT",FwFldGet("CCUSTOPROP"),"CTT_DESC01")," ")' /*cRegra*/, .F. /*lSeek*/, /*cAlias*/,  /*nOrdem*/, /*cChave*/, /*cCondic*/ )
	oStruct:AddTrigger( aGatilho[1] , aGatilho[2] , aGatilho[3], aGatilho[4])
	
Return oStruct

/*{Protheus.doc} FSATUDESC
Atualiza a descri��o do cargo
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return cDescCarg, descri��o cargo 
*/
User Function FSATUDESC()

	Local oModAtu  := FWModelActive()
	Local cFilAtu  := oModAtu:GetModel("TRFDETAIL"):GetValue("TMP_FILIAL")
	Local cFilProp := oModAtu:GetModel("TRFDETAIL"):GetValue("FILIPROP")
	Local cCodProp := oModAtu:GetModel("TRFDETAIL"):GetValue("POSTOPROP")
	
	If Empty(cFilProp)
		cFilProp := cFilAtu
	EndIf
	
	cCargo := POSICIONE("RCL",2,cFilProp+cCodProp,"RCL_CARGO")
	
	cDescCarg := POSICIONE("SQ3",1,xFilial("SQ3")+cCargo,"Q3_DESCSUM")

Return cDescCarg

/*{Protheus.doc} MDStrRB6
Retorna o sub-modelo Tabela Salarial contido no sub-modelo Altera��o Salarial
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Retorna o sub-modelo Tabela Salarial com os campos e regras}
*/
Static Function MDStrRB6()
	
	Local oStruct := FWFormModelStruct():New()
	
	oStruct:AddTable("TABSAL", {" "}, "Itens da Tabela Salarial")
	
	oStruct:AddField(Alltrim(GetSx3Cache("RB6_NIVEL","X3_TITULO"))	    ,;	// 	[01]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RB6_NIVEL","X3_DESCRIC"))		,;	// 	[02]  C   ToolTip do campo
	                 "NIVELATU"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RB6_NIVEL","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_NIVEL")[1]								,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RB6_NIVEL")[2]								,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 Nil												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Faixa"							                ,;	// 	[01]  C   Titulo do campo
	                 "Faixa"								      	    ,;	// 	[02]  C   ToolTip do campo
	                 "FAIXAATU"									        ,;	// 	[03]  C   Id do Field
	                 "C"										        ,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_FAIXA")[1]						        ,;	// 	[05]  N   Tamanho do campo
	                 0											        ,;	// 	[06]  N   Decimal do campo
	                 NIL										        ,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}									        ,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL										        ,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.										        ,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL										        ,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL										        ,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.										        ,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.										        )	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Valor"							                ,;	// 	[01]  C   Titulo do campo
	                 "Valor"									        ,;	// 	[02]  C   ToolTip do campo
	                 "VALORATU"									        ,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RB6_VALOR","X3_TIPO"	)        		,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_VALOR")[1]						        ,;	// 	[05]  N   Tamanho do campo
	                 TamSX3("RB6_VALOR")[2]						        ,;	// 	[06]  N   Decimal do campo
	                 NIL										        ,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}									        ,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL										        ,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.										        ,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL										        ,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL										        ,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.										        ,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.										        )   // 	[14]  L   Indica se o campo � virtual
	
Return oStruct

/*{Protheus.doc} MDStrPrp
Sub-Modelo Tabela Proporcional Tempor�ria do aba Altera��o Salarial
@type Static function
@author Cris
@since 03/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Retorna o sub-modelo Tabela Proporcional Tempor�ria}
*/
Static Function MDStrPrp()
	
	Local oStruct := FWFormModelStruct():New()
	
	oStruct:AddTable("TABSALPROP", {" "}, "Itens da Tabela Salarial Proporcional")
	
	oStruct:AddField("NIVEL"									        ,;	// 	[01]  C   Titulo do campo
	                 "Faixa"											,;	// 	[02]  C   ToolTip do campo
	                 "NIVELTMP"											,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_NIVEL")[1]								,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Faixa"									        ,;	// 	[01]  C   Titulo do campo
	                 "Faixa"											,;	// 	[02]  C   ToolTip do campo
	                 "FAIXATMP"											,;	// 	[03]  C   Id do Field
	                 "C"												,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_FAIXA")[1]								,;	// 	[05]  N   Tamanho do campo
	                 0													,;	// 	[06]  N   Decimal do campo
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
	oStruct:AddField("Valor Proporcional"						        ,;	// 	[01]  C   Titulo do campo
	                 "Valor Proporcional"								,;	// 	[02]  C   ToolTip do campo
	                 "VALORTMP"											,;	// 	[03]  C   Id do Field
	                 GetSx3Cache("RB6_VALOR","X3_TIPO"	)				,;	// 	[04]  C   Tipo do campo
	                 TamSX3("RB6_VALOR")[1]								,;	// 	[05]  N   Tamanho do campo
	                 2													,;	// 	[06]  N   Decimal do campo//TamSX3("RB6_VALOR")[2]
	                 NIL												,;	// 	[07]  B   Code-block de valida��o do campo
	                 {|| .T.}											,;	// 	[08]  B   Code-block de valida��o When do campo
	                 NIL												,;	//	[09]  A   Lista de valores permitido do campo
	                 .F.												,;	//	[10]  L   Indica se o campo tem preenchimento obrigat�rio
	                 NIL												,;  //	[11]  B   Code-block de inicializacao do campo
	                 NIL												,;	//	[12]  L   Indica se trata-se de um campo chave
	                 .T.												,;	//	[13]  L   Indica se o campo pode receber valor em uma opera��o de update.
	                 .T.												)	// 	[14]  L   Indica se o campo � virtual
	
Return oStruct

/*{Protheus.doc} VIEWDEF
Modelo de Visualiza��o
@type  Static function
@author Cris
@since 20/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oView}, ${Modelo da Visualiza��o}
*/
Static Function ViewDef()
	
	Local oModel   := FWLoadModel( 'F0500401' )
	Local oStrMov  := VWStrCab()
	Local oStrTSal := VWStrRB6()//Itens da tabela salarial (Faixa e Nivel)
	Local oStrPnal := VWStrTMP()//Itens da tabela salarial tempor�ria (Faixa e Nivel)
	Local oStrSal  := VWStrSal()
	Local oStrCar  := VWStrCar()
	Local oStrHor  := VWStrHor()
	Local oStrTur  := VWStrTur()
	Local oStrTrf  := VWStrTrf()
	
//	Private oView // gus
	Public  oView // gus
	
	oView := FWFormView():New()
	oView:SetModel( oModel )
	
	oView:AddField( 'VIEW_RH3'	, oStrMov	, "F0500401" )
	oView:AddField( 'VIEW_SAL'	, oStrSal	, 'SALDETAIL' )
	oView:AddGrid(	'VIEW_RB6'	,oStrTSal	, 'RB6DETAIL' )
	oView:AddGrid(	'VIEW_TMP'	,oStrPnal	, 'TMPDETAIL' )
	oView:AddField( 'VIEW_CAR'	, oStrCar	, 'CARDETAIL' )
	oView:AddField( 'VIEW_HOR'	, oStrHor	, 'HORDETAIL' )
	oView:AddField( 'VIEW_TUR'	, oStrTur	, 'TURDETAIL' )
	oView:AddField( 'VIEW_TRF'	, oStrTrf	, 'TRFDETAIL' )
	
	oView:CreateHorizontalBox( 'SUPERIOR', 10 )
	oView:CreateHorizontalBox( 'INFERIOR', 90 )
	
	// Crias as folders
	oView:CreateFolder('PASTAS','INFERIOR')
	
	oView:AddSheet('PASTAS','ABASAL','Altera��o Salarial')
	oView:AddSheet('PASTAS','ABACAR','Altera��o de Cargo')
	oView:AddSheet('PASTAS','ABAHOR','Altera��o de Carga Horaria')
	oView:AddSheet('PASTAS','ABATUR','Altera��o de Troca de Turno')
	oView:AddSheet('PASTAS','ABATRF','Altera��o->Transfer�ncia')
	
	oView:CreateHorizontalBox('AREASAL'		,70,,,'PASTAS','ABASAL')
	oView:CreateHorizontalBox('ATABSAL'		,30,,,'PASTAS','ABASAL')
	oView:CreateHorizontalBox('AREACAR'		,100,,,'PASTAS','ABACAR')
	oView:CreateHorizontalBox('AREAHOR'		,100,,,'PASTAS','ABAHOR')
	oView:CreateHorizontalBox('AREATUR'		,100,,,'PASTAS','ABATUR')
	oView:CreateHorizontalBox('AREATRF'		,100,,,'PASTAS','ABATRF')
	
	// Dividir o box da tabela(s) salarial(is)
	oView:CreateVerticalBox('AREARB6',50,'ATABSAL',,'PASTAS','ABASAL')
	oView:CreateVerticalBox('AREATMP',50,'ATABSAL',,'PASTAS','ABASAL')
	
	// Aloca as Views nas suas respectivas �reas
	oView:SetOwnerView( 'VIEW_RH3', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_SAL', 'AREASAL' )
	oView:SetOwnerView( 'VIEW_RB6', 'AREARB6' )
	oView:SetOwnerView( 'VIEW_TMP', 'AREATMP' )
	oView:SetOwnerView( 'VIEW_CAR', 'AREACAR' )
	oView:SetOwnerView( 'VIEW_HOR', 'AREAHOR' )
	oView:SetOwnerView( 'VIEW_TUR', 'AREATUR' )
	oView:SetOwnerView( 'VIEW_TRF', 'AREATRF' )
	
Return oView

/*{Protheus.doc} VWStrCab
Estrutura do cabe�alho a ser visualizado
@type Static function
@author Cris
@since 25/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Estrutura do cabe�alho a ser visualizado}
*/
Static Function VWStrCab()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddField("RH3_MAT"								            ,;	// [01]  C   Nome do Campo
	                 "01"									    	    ,;	// [02]  C   Ordem
	                 'Matricula'								    	,;	// [03]  C   Titulo do campo
	                 'Matricula'									    ,;	// [04]  C   Descricao do campo
	                 NIL								     			,;	// [05]  A   Array com Help
	                 "C"									    		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_MAT","X3_PICTURE")			        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL		     									,;	// [09]  C   Consulta F3
	                 .F.			    								,;	// [10]  L   Indica se o campo � alteravel
	                 NIL				    							,;	// [11]  C   Pasta do campo
	                 NIL					    						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("RH3_NOME"				        				    ,;	// [01]  C   Nome do Campo
	                 "02"							        			,;	// [02]  C   Ordem
	                 'Nome do Funcion�rio'					        	,;	// [03]  C   Titulo do campo
	                 'Nome do Funcion�rio'	         					,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"											    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RH3_NOME","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL										     	,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL										    	,;	// [11]  C   Pasta do campo
	                 NIL			     								,;	// [12]  C   Agrupamento do campo
	                 NIL				    							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("RH3DTSOLI"							            ,;	// [01]  C   Nome do Campo
	                 "03"										        ,;	// [02]  C   Ordem
	                 "M�s/Ano Solicita��o"      						,;	// [03]  C   Titulo do campo
	                 "M�s/Ano Solicita��o"		        				,;	// [04]  C   Descricao do campo
	                 NIL								     			,;	// [05]  A   Array com Help
	                 "C"									    		,;	// [06]  C   Tipo do campo
	                 NIL										    	,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL		 	    								,;	// [11]  C   Pasta do campo
	                 NIL				       							,;	// [12]  C   Agrupamento do campo
	                 NIL					    						,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL						    					,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL							    				,;	// [15]  C   Inicializador de Browse
	                 .T.								    			,;	// [16]  L   Indica se o campo � virtual
	                 NIL				 					    		,;	// [17]  C   Picture Variavel
	                 NIL										    	)	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} VWStrSal
Estrutura a ser visualizada na aba Altera��o Salarial
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Retorna a estrutura a ser visualizada na aba Altera��o salarial parte superior}
*/
Static Function VWStrSal()
	
	Local lVirtual := .F.
	Local oStruct  := FWFormViewStruct():New()
	
	oStruct:AddGroup( "DDATUAIS" 		, "Informa��es Atuais", "" , 2 )
	oStruct:AddGroup( "DDPROPOSTOS" 	, "Informa��es da Proposta", "" , 2 )
	
	oStruct:AddField("TMP_CARGO"							            ,;	// [01]  C   Nome do Campo
	                 "01"								         		,;	// [02]  C   Ordem
	                 "C�digo do Cargo"							        ,;	// [03]  C   Titulo do campo
	                 "C�digo do Cargo"       							,;	// [04]  C   Descricao do campo
	                 NIL					    						,;	// [05]  A   Array com Help
                   	 "C"						    					,;	// [06]  C   Tipo do campo
	                 ""								         			,;	// [07]  C   Picture
	                 NIL									     		,;	// [08]  B   Bloco de Picture Var
	                 NIL										    	,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL		    									,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 	     								,;	// [12]  C   Agrupamento do campo
	                 NIL				     							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_FUNC"							            ,;	// [01]  C   Nome do Campo
	                 "02"										        ,;	// [02]  C   Ordem
	                 "Descri��o do Cargo"       						,;	// [03]  C   Titulo do campo
	                 "Descri��o do Cargo"		        				,;	// [04]  C   Descricao do campo
	                 NIL								     			,;	// [05]  A   Array com Help
	                 "C"									     		,;	// [06]  C   Tipo do campo
	                 ""											        ,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"			        						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_SALATU"		             					,;	// [01]  C   Nome do Campo
	                 "03"							        			,;	// [02]  C   Ordem
	                 'Sal�rio Atual'						    		,;	// [03]  C   Titulo do campo
	                 'Sal�rio Atual'							    	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "N"								    			,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_SALARIO","X3_PICTURE")	        	,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL		     									,;	// [09]  C   Consulta F3
	                 .F.			    								,;	// [10]  L   Indica se o campo � alteravel
	                 NIL				    							,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 			    						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_TABELA"						                ,;	// [01]  C   Nome do Campo
	                 "04"										        ,;	// [02]  C   Ordem
	                 Alltrim(GetSx3Cache("RA_TABELA","X3_TITULO"))	    ,;	// [03]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABELA","X3_DESCRIC"))     ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TABELA","X3_TIPO")			        ,;	// [06]  C   Tipo do campo
	                 ""											        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3 //"RB601"
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"									        ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_NIVELT"						                ,;	// [01]  C   Nome do Campo
	                 "05"									        	,;	// [02]  C   Ordem
	                 Alltrim(GetSx3Cache("RA_TABNIVE","X3_TITULO"))	    ,;	// [03]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABNIVE","X3_DESCRIC"))    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TABNIVE","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 ""											        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"											,;	// [12]  C   Agrupamento do campo
                     NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL			 								    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_FAIXAT"						                ,;	// [01]  C   Nome do Campo
	                 "06"										        ,;	// [02]  C   Ordem
	                 Alltrim(GetSx3Cache("RA_TABFAIX","X3_TITULO"))	    ,;	// [03]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TABFAIX","X3_DESCRIC"))    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TABFAIX","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 ""											        ,;	// [07]  C   Picture
	                 NIL			    								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3//"RB605"
	                 .F.					    						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"						         			,;	// [12]  C   Agrupamento do campo
	                 NIL									    		,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										    	,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("SALARIOPROP"							            ,;	// [01]  C   Nome do Campo
	                 "07"					         					,;	// [02]  C   Ordem
	                 'Sal�rio Proposto'				        			,;	// [03]  C   Titulo do campo
	                 'Sal�rio Proposto'						        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "N"											    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_SALARIO","X3_PICTURE")		        ,;	// [07]  C   Picture
                     NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"									    ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										 	    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_SALHR"							            ,;	// [01]  C   Nome do Campo
	                 "07"					         					,;	// [02]  C   Ordem
	                 'Sal�rio Hora'				        			    ,;	// [03]  C   Titulo do campo
	                 'Sal�rio Hora'						        	    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "N"											    ,;	// [06]  C   Tipo do campo
	                 "@E 999,999.999999999"             		        ,;	// [07]  C   Picture   COMENTADO -> /*GetSx3Cache("RA_SALARIO","X3_PICTURE")*/
                     NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"									    ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										 	    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_VLSALA"							            ,;	// [01]  C   Nome do Campo
	                 "08"										        ,;	// [02]  C   Ordem
	                 'Valor Reajuste'							        ,;	// [03]  C   Titulo do campo
	                 'Valor Reajuste'							        ,;	// [04]  C   Descricao do campo
	                 NIL										     	,;	// [05]  A   Array com Help
	                 "N"										    	,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_SALARIO","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL									    		,;	// [08]  B   Bloco de Picture Var
	                 NIL					     						,;	// [09]  C   Consulta F3
	                 .T.					       						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"	         							,;	// [12]  C   Agrupamento do campo
	                 NIL			     								,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL				    							,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL					    						,;	// [15]  C   Inicializador de Browse
	                 .T.						     					,;	// [16]  L   Indica se o campo � virtual
	                 NIL							    				,;	// [17]  C   Picture Variavel
	                 NIL								    			)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_PERCSA"				             			,;	// [01]  C   Nome do Campo
	                 "09"									        	,;	// [02]  C   Ordem
	                 'Percentual do Reajuste'    						,;	// [03]  C   Titulo do campo
	                 'Percentual do Reajuste'	    					,;	// [04]  C   Descricao do campo
	                 NIL							    				,;	// [05]  A   Array com Help
	                 "N"								    			,;	// [06]  C   Tipo do campo
	                 "@E 999.99"							   		    ,;	// [07]  C   Picture
	                 NIL     										   	,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .T.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"		    						    ,;	// [12]  C   Agrupamento do campo
	                 NIL					    						,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL						    					,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL							     				,;	// [15]  C   Inicializador de Browse
	                 .T.								    			,;	// [16]  L   Indica se o campo � virtual
	                 NIL									    		,;	// [17]  C   Picture Variavel
	                 NIL										    	)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("MOTALTSAL"							            ,;	// [01]  C   Nome do Campo
	                 "10"										        ,;	// [02]  C   Ordem
	                 Alltrim(GetSx3Cache("RA_TIPOALT","X3_TITULO"))  	,;	// [03]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RA_TIPOALT","X3_DESCRIC"))    ,;	// [04]  C   Descricao do campo
	                 NIL										     	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TIPOALT","X3_TIPO")	    		,;	// [06]  C   Tipo do campo
	                 ""     											,;	// [07]  C   Picture
	                 NIL	    										,;	// [08]  B   Bloco de Picture Var
	                 '41'		        								,;	// [09]  C   Consulta F3
	                 .T.				    							,;	// [10]  L   Indica se o campo � alteravel
	                 NIL					    						,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"				        				,;	// [12]  C   Agrupamento do campo
	                 NIL								    			,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL									    		,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL										    	,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_MOT"             							,;	// [01]  C   Nome do Campo
	                 "11"					        					,;	// [02]  C   Ordem
	                 "Descri��o do Motivo Salarial"	        			,;	// [03]  C   Titulo do campo
	                 "Descri��o do Motivo Salarial"			        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"     											,;	// [06]  C   Tipo do campo
	                 ""		        									,;	// [07]  C   Picture
	                 NIL			     								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3
	                 .F.					    						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"					        			,;	// [12]  C   Agrupamento do campo
	                 NIL									    		,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										    	,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo

	oStruct:AddField("TMP_ESCL"             							,;	// [01]  C   Nome do Campo
	                 "12"					        					,;	// [02]  C   Ordem
	                 "M�rito"                   	        			,;	// [03]  C   Titulo do campo
	                 "M�rito"                   			        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"     											,;	// [06]  C   Tipo do campo
	                 ""		        									,;	// [07]  C   Picture
	                 NIL			     								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3
	                 .T.					    						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"					        			,;	// [12]  C   Agrupamento do campo
	                 {"1=SIM","2=NAO"}							    	,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										    	,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} VWStrCar
Estrutura a ser visualizada na aba Altera��o de Cargo
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Estrutura a ser visualizada na aba Altera��o de Cargo}
*/
Static Function VWStrCar()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddGroup( "DDATUAIS" 		, "Informa��es Atuais", "" , 2 )
	oStruct:AddGroup( "DDPROPOSTOS" 	, "Informa��es da Proposta", "" , 2 )
	
	oStruct:AddField("TMP_CARGO"							            ,;	// [01]  C   Nome do Campo
	                 "01"						        				,;	// [02]  C   Ordem
	                 "C�digo do Cargo"	        		  				,;	// [03]  C   Titulo do campo
	                 "C�digo do Cargo"						        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"    											,;	// [06]  C   Tipo do campo
	                 ""		        									,;	// [07]  C   Picture
	                 NIL			     								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3
	                 .F.					    						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 					    				,;	// [12]  C   Agrupamento do campo
	                 NIL								    			,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL									    		,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL										    	,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL					    						,;	// [17]  C   Picture Variavel
	                 NIL						    					)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_FUNC"           							,;	// [01]  C   Nome do Campo
	                 "02"					        					,;	// [02]  C   Ordem
	                 "Descri��o do Cargo"			        			,;	// [03]  C   Titulo do campo
	                 "Descri��o do Cargo"					        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"	    		 								,;	// [06]  C   Tipo do campo
	                 ""			        								,;	// [07]  C   Picture
	                 NIL				    							,;	// [08]  B   Bloco de Picture Var
	                 NIL					    						,;	// [09]  C   Consulta F3
	                 .F.						    					,;	// [10]  L   Indica se o campo � alteravel
	                 NIL							    				,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"							        		,;	// [12]  C   Agrupamento do campo
	                 NIL										    	,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL    											,;	// [15]  C   Inicializador de Browse
	                 .T.	    										,;	// [16]  L   Indica se o campo � virtual
	                 NIL		    									,;	// [17]  C   Picture Variavel
	                 NIL			    								)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("CARGOPROP"				        				,;	// [01]  C   Nome do Campo
	                 "03"								        		,;	// [02]  C   Ordem
	                 "C�digo do Cargo"							        ,;	// [03]  C   Titulo do campo
	                 "C�digo do Cargo"      							,;	// [04]  C   Descricao do campo
	                 NIL					     						,;	// [05]  A   Array com Help
	                 "C"						    					,;	// [06]  C   Tipo do campo
	                 ""								        			,;	// [07]  C   Picture
	                 NIL									    		,;	// [08]  B   Bloco de Picture Var
	                 "SQ3"										        ,;	// [09]  C   Consulta F3
	                 .T.	    										,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 		        						,;	// [12]  C   Agrupamento do campo
	                 NIL						     					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
   	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_F_PP"				            			,;	// [01]  C   Nome do Campo
	                 "04"									        	,;	// [02]  C   Ordem
	                 "Descri��o do Cargo"        						,;	// [03]  C   Titulo do campo
	                 "Descri��o do Cargo"		        				,;	// [04]  C   Descricao do campo
	                 NIL								    			,;	// [05]  A   Array com Help
	                 "C"									    		,;	// [06]  C   Tipo do campo
	                 ""											        ,;	// [07]  C   Picture
	                 NIL     											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"		        						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("MALTCARSAL"           							,;	// [01]  C   Nome do Campo
	                 "05"					        					,;	// [02]  C   Ordem
	                 "Motivo da Altera��o"			         			,;	// [03]  C   Titulo do campo
	                 "Motivo da Altera��o"					         	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TIPOALT","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 ""		         									,;	// [07]  C   Picture
	                 NIL			    								,;	// [08]  B   Bloco de Picture Var
	                 '41'				        						,;	// [09]  C   Consulta F3
 	                 .T.						    					,;	// [10]  L   Indica se o campo � alteravel
	                 NIL							    				,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"								        ,;	// [12]  C   Agrupamento do campo
	                 NIL	     										,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL		     									,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL			    								,;	// [15]  C   Inicializador de Browse
	                 .T.				    							,;	// [16]  L   Indica se o campo � virtual
	                 NIL					    						,;	// [17]  C   Picture Variavel
	                 NIL						    					)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_MOTC"           							,;	// [01]  C   Nome do Campo
	                 "06"					        					,;	// [02]  C   Ordem
	                 "Descri��o do Motivo Salarial"	        			,;	// [03]  C   Titulo do campo
	                 "Descri��o do Motivo Salarial"			        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"    											,;	// [06]  C   Tipo do campo
	                 ""		        									,;	// [07]  C   Picture
	                 NIL			    								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3
	                .F.						        					,;	// [10]  L   Indica se o campo � alteravel
	                NIL								    	    		,;	// [11]  C   Pasta do campo
	                "DDPROPOSTOS"						     	    	,;	// [12]  C   Agrupamento do campo
	                NIL	        										,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                NIL			        								,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                NIL					        						,;	// [15]  C   Inicializador de Browse
	                .T.							        				,;	// [16]  L   Indica se o campo � virtual
	                NIL									        		,;	// [17]  C   Picture Variavel
	                NIL											        )	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} VWStrHor
Estrutura a ser visualizada na aba Carga Hor�ria
@type Static function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Estrutura a ser visualizada na aba Carga Hor�ria}
*/
Static Function VWStrHor()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddGroup( "DDATUAIS" 		, "Informa��es Atuais", "" , 2 )
	oStruct:AddGroup( "DDPROPOSTOS" 	, "Informa��es da Proposta", "" , 2 )
	
	oStruct:AddField("TMP_H_M_AT"							            ,;	// [01]  C   Nome do Campo
	                 "01"										        ,;	// [02]  C   Ordem
	                 "Horas Mensais"    								,;	// [03]  C   Titulo do campo
	                 "Horas Mensais"	    							,;	// [04]  C   Descricao do campo
	                 NIL					    						,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSMES","X3_TIPO")	        		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSMES","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL     											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 		    							,;	// [12]  C   Agrupamento do campo
	                 NIL					    						,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL						    					,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL							    				,;	// [15]  C   Inicializador de Browse
	                 .T.								     			,;	// [16]  L   Indica se o campo � virtual
	                 NIL									    		,;	// [17]  C   Picture Variavel
	                 NIL										    	)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_H_S_AT"	            						,;	// [01]  C   Nome do Campo
	                 "02"						        				,;	// [02]  C   Ordem
	                 "Horas Semanais"					        		,;	// [03]  C   Titulo do campo
	                 "Horas Semanais"							        ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSEMAN","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSEMAN","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"			        						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	
	oStruct:AddField("TMP_H_D_AT"								        ,;	// [01]  C   Nome do Campo
	                 "03"								        		,;	// [02]  C   Ordem
	                 "Horas Dias"								        ,;	// [03]  C   Titulo do campo
	                 "Horas Dias"						         		,;	// [04]  C   Descricao do campo
	                 NIL									    		,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSDIA","X3_TIPO")		         	,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSDIA","X3_PICTURE")	        	,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 		    							,;	// [12]  C   Agrupamento do campo
	                 NIL					    						,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL						    					,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL							    				,;	// [15]  C   Inicializador de Browse
	                 .T.								    			,;	// [16]  L   Indica se o campo � virtual
	                 NIL									    		,;	// [17]  C   Picture Variavel
	                 NIL										     	)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("HMESPROP"			        						,;	// [01]  C   Nome do Campo
	                 "04"						        				,;	// [02]  C   Ordem
	                 "Horas Mensais"					    			,;	// [03]  C   Titulo do campo
	                 "Horas Mensais"						    		,;	// [04]  C   Descricao do campo
	                 NIL										    	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSMES","X3_TIPO")	        		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSMES","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 								        ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("HSEMPROP"         								,;	// [01]  C   Nome do Campo
	                 "05"				        						,;	// [02]  C   Ordem
	                 "Horas Semanais"			         				,;	// [03]  C   Titulo do campo
	                 "Horas Semanais"					        		,;	// [04]  C   Descricao do campo
	                 NIL										    	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSEMAN","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSEMAN","X3_PICTURE")     		,;	// [07]  C   Picture
	                 NIL										    	,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"								        ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL								    			,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL									     		,;	// [15]  C   Inicializador de Browse
	                 .T.										    	,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("HDIAPROP"		        							,;	// [01]  C   Nome do Campo
	                 "06"					        					,;	// [02]  C   Ordem
	                 "Horas Dias"					        			,;	// [03]  C   Titulo do campo
	                 "Horas Dias"							        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_HRSDIA","X3_TIPO")      			,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_HRSDIA","X3_PICTURE")	        	,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 							        	,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL										 	    )	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} VWStrTur
Estrutura a ser visualizada na aba Turno
@type function
@author Cris
@since 24/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo contendo a Estrutura a ser visualizada na aba Carga Hor�ria}
*/
Static Function VWStrTur()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddGroup( "DDATUAIS" 		, "Informa��es Atuais", "" , 2 )
	oStruct:AddGroup( "DDPROPOSTOS" 	, "Informa��es da Proposta", "" , 2 )
	
	oStruct:AddField("TMP_TURNAT"							            ,;	// [01]  C   Nome do Campo
	                 "01"				         						,;	// [02]  C   Ordem
	                 "Turno de Trabalho"		     					,;	// [03]  C   Titulo do campo
	                 "Turno de Trabalho"			    				,;	// [04]  C   Descricao do campo
	                 NIL								    			,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TNOTRAB","X3_TIPO")	    		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_TNOTRAB","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL	    										,;	// [08]  B   Bloco de Picture Var
	                 NIL		     									,;	// [09]  C   Consulta F3
	                 .F.			    								,;	// [10]  L   Indica se o campo � alteravel
	                 NIL				    							,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 			    						,;	// [12]  C   Agrupamento do campo
	                 NIL						    					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_TURN"	            						,;	// [01]  C   Nome do Campo
	                 "02"						        				,;	// [02]  C   Ordem
	                 "Descri��o do Turno"				        		,;	// [03]  C   Titulo do campo
	                 "Descri��o do Turno"						        ,;	// [04]  C   Descricao do campo
 	                 NIL     											,;	// [05]  A   Array com Help
	                 "C"	      										,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_DESCTUR","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"								         	,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_S_TURN"				          				,;	// [01]  C   Nome do Campo
	                 "03"									        	,;	// [02]  C   Ordem
	                 "Seq.Ini.Turno"								    ,;	// [03]  C   Titulo do campo
	                 "Seq.Ini.Turno"								    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_SEQTURN","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_SEQTURN","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL	    										,;	// [08]  B   Bloco de Picture Var
	                 NIL		     									,;	// [09]  C   Consulta F3
	                 .F.			    								,;	// [10]  L   Indica se o campo � alteravel
	                 NIL				    							,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 			    						,;	// [12]  C   Agrupamento do campo
	                 NIL                                                ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL					    						,;	// [15]  C   Inicializador de Browse
	                 .T.						    					,;	// [16]  L   Indica se o campo � virtual
	                 NIL							    				,;	// [17]  C   Picture Variavel
	                 NIL								    			)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_REGRA"							        	,;	// [01]  C   Nome do Campo
	                 "04"										        ,;	// [02]  C   Ordem
	                 "Regra"	    									,;	// [03]  C   Titulo do campo
	                 "Regra"		    								,;	// [04]  C   Descricao do campo
	                 NIL										    	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_REGRA","X3_TIPO")			        ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_REGRA","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 									    ,;	// [12]  C   Agrupamento do campo
	                 NIL										    	,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL										    	)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TURNOPROP"							            ,;	// [01]  C   Nome do Campo
	                 "06"										        ,;	// [02]  C   Ordem
	                 "Turno de Trabalho"							    ,;	// [03]  C   Titulo do campo
	                 "Turno de Trabalho"							    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_TNOTRAB","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_TNOTRAB","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 "SR6"										        ,;	// [09]  C   Consulta F3
	                 .T.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL	    										,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"       								,;	// [12]  C   Agrupamento do campo
	                 NIL				    							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_DESCTU"		            					,;	// [01]  C   Nome do Campo
	                 "07"							        			,;	// [02]  C   Ordem
	                 "Descri��o do Turno"					        	,;	// [03]  C   Titulo do campo
	                 "Descri��o do Turno"       						,;	// [04]  C   Descricao do campo
	                 NIL						     					,;	// [05]  A   Array com Help
	                 ""									        		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache(" RA_DESCTUR","X3_PICTURE")	    	,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL						     					,;	// [09]  C   Consulta F3
	                 .F.							    				,;	// [10]  L   Indica se o campo � alteravel
	                 NIL								    			,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"							        	,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("STURPROP"			        						,;	// [01]  C   Nome do Campo
	                 "08"						        				,;	// [02]  C   Ordem
	                 "Seq.Ini.Turno"					     			,;	// [03]  C   Titulo do campo
	                 "Seq.Ini.Turno"						    		,;	// [04]  C   Descricao do campo
	                 NIL										    	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_SEQTURN","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_SEQTURN","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL					    						,;	// [08]  B   Bloco de Picture Var
	                 "XPJ"						        				,;	// [09]  C   Consulta F3
	                 .F.								    			,;	// [10]  L   Indica se o campo � alteravel
	                 NIL									    		,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 								        ,;	// [12]  C   Agrupamento do campo
	                 NIL				     							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("REGRAPROP"	        							,;	// [01]  C   Nome do Campo
	                 "09"								         		,;	// [02]  C   Ordem
	                 "Regra"									    	,;	// [03]  C   Titulo do campo
	                 "Regra"										    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RA_REGRA","X3_TIPO")	        		,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RA_REGRA","X3_PICTURE")		        ,;	// [07]  C   Picture
	                 NIL								    			,;	// [08]  B   Bloco de Picture Var
	                 "SPA"									        	,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL										     	,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 								        ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
        	         NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} $VWStrTrf
Estrutura a ser visualizada na aba Transfer�ncia
@type function
@author Cris
@since 25/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo da Estrutura a ser visualizada na aba Transfer�ncia}
*/
Static Function VWStrTrf()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddGroup( "DDATUAIS" 		, "Informa��es Atuais", "" , 2 )
	oStruct:AddGroup( "DDPROPOSTOS" 	, "Informa��es da Proposta", "" , 2 )
	
	oStruct:AddField("TMP_FILIAL"								        ,;	// [01]  C   Nome do Campo
	                 "01"										        ,;	// [02]  C   Ordem
	                 "Filial"							        		,;	// [03]  C   Titulo do campo
	                 "Filial"       									,;	// [04]  C   Descricao do campo
	                 NIL				      							,;	// [05]  A   Array com Help
	                 "C"						     					,;	// [06]  C   Tipo do campo
	                 NIL							    				,;	// [07]  C   Picture
	                 NIL								     			,;	// [08]  B   Bloco de Picture Var
	                 NIL									    		,;	// [09]  C   Consulta F3
	                 .F.										    	,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"     									,;	// [12]  C   Agrupamento do campo
	                 NIL			    								,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL				    							,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL					    						,;	// [15]  C   Inicializador de Browse
	                 .T.						    					,;	// [16]  L   Indica se o campo � virtual
	                 NIL							    				,;	// [17]  C   Picture Variavel
	                 NIL								    			)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_FILI"						        		,;	// [01]  C   Nome do Campo
        	         "02" 										        ,;	// [02]  C   Ordem
	                 "Nome da Filial"        							,;	// [03]  C   Titulo do campo
	                 "Nome da Filial"		        					,;	// [04]  C   Descricao do campo
	                 NIL							    				,;	// [05]  A   Array com Help
	                 "C"								    			,;	// [06]  C   Tipo do campo
	                 NIL									    		,;	// [07]  C   Picture
	                 NIL										    	,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 									    ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL										 	    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_CCATU"            							,;	// [01]  C   Nome do Campo
	                 "03"					        					,;	// [02]  C   Ordem
	                 "Centro de Custo"				        			,;	// [03]  C   Titulo do campo
	                 "Centro de Custo"						        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"											    ,;	// [06]  C   Tipo do campo
	                 NIL    											,;	// [07]  C   Picture
	                 NIL	    										,;	// [08]  B   Bloco de Picture Var
 	                 NIL		    									,;	// [09]  C   Consulta F3
	                 .F.			    								,;	// [10]  L   Indica se o campo � alteravel
	                 NIL				    							,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 			    						,;	// [12]  C   Agrupamento do campo
	                 NIL						     					,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL							    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL								    			,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_CCAT"           							,;	// [01]  C   Nome do Campo
	                 "04"					        					,;	// [02]  C   Ordem
	                 "Descri��o Centro de Custo"	     				,;	// [03]  C   Titulo do campo
	                 "Descri��o Centro de Custo"		    			,;	// [04]  C   Descricao do campo
	                 NIL									    		,;	// [05]  A   Array com Help
	                 "C"										    	,;	// [06]  C   Tipo do campo
	                 NIL											    ,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDATUAIS"							        		,;	// [12]  C   Agrupamento do campo
	                 NIL		    									,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL			    								,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL				    							,;	// [15]  C   Inicializador de Browse
	                 .T.					    						,;	// [16]  L   Indica se o campo � virtual
	                 NIL						    					,;	// [17]  C   Picture Variavel
	                 NIL							    				)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_DEPTOA"	        							,;	// [01]  C   Nome do Campo
	                 "05"					        					,;	// [02]  C   Ordem
	                 "Departamento"					        			,;	// [03]  C   Titulo do campo
	                 "Departamento"							        	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 "C"    											,;	// [06]  C   Tipo do campo
	                 NIL	    										,;	// [07]  C   Picture
	                 NIL		    									,;	// [08]  B   Bloco de Picture Var
	                 NIL			    								,;	// [09]  C   Consulta F3
	                 .F.				    							,;	// [10]  L   Indica se o campo � alteravel
	                 NIL					    						,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 				    					,;	// [12]  C   Agrupamento do campo
	                 NIL							    				,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL								    			,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL									    		,;	// [15]  C   Inicializador de Browse
	                 .T.										    	,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL	    										)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_DEPT"       								,;	// [01]  C   Nome do Campo
	                 "06"				        						,;	// [02]  C   Ordem
	                 "Nome do Departamento"		        				,;	// [03]  C   Titulo do campo
	                 "Nome do Departamento"				        		,;	// [04]  C   Descricao do campo
	                 NIL										    	,;	// [05]  A   Array com Help
	                 "C"											    ,;	// [06]  C   Tipo do campo
	                 NIL											    ,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL			 								    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
 	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 "DDATUAIS" 				     					,;	// [12]  C   Agrupamento do campo
	                 NIL							    				,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL								    			,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL									    		,;	// [15]  C   Inicializador de Browse
	                 .T.										    	,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	//SIGAORG como posto
	if cTipOrgA == '1'
		
		oStruct:AddField("TMP_POSTO"							        ,;	// [01]  C   Nome do Campo
		                 "07"										    ,;	// [02]  C   Ordem
		                 "Posto"										,;	// [03]  C   Titulo do campo
		                 "Posto"										,;	// [04]  C   Descricao do campo
		                 NIL											,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_POSTO","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_POSTO","X3_PICTURE")		    ,;	// [07]  C   Picture
		                 NIL											,;	// [08]  B   Bloco de Picture Var
		                 NIL											,;	// [09]  C   Consulta F3
		                 .F.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDATUAIS" 									,;	// [12]  C   Agrupamento do campo
		                 NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
		
		oStruct:AddField("TMP_DFUNCAO"       							,;	// [01]  C   Nome do Campo
		                 "08"				        					,;	// [02]  C   Ordem
		                 "Descri��o Cargo"					         	,;	// [03]  C   Titulo do campo
		                 "Descri��o Cargo"							    ,;	// [04]  C   Descricao do campo
		                 NIL										    ,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_DCARGO","X3_TIPO")		        ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_DCARGO","X3_PICTURE")		    ,;	// [07]  C   Picture
		                 NIL     										,;	// [08]  B   Bloco de Picture Var
		                 NIL	    									,;	// [09]  C   Consulta F3
		                 .F.		     								,;	// [10]  L   Indica se o campo � alteravel
		                 NIL			    							,;	// [11]  C   Pasta do campo
		                 "DDATUAIS" 		    						,;	// [12]  C   Agrupamento do campo
		                 NIL					     					,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL						    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL							    			,;	// [15]  C   Inicializador de Browse
		                 .T.								    		,;	// [16]  L   Indica se o campo � virtual
		                 NIL									    	,;	// [17]  C   Picture Variavel
		                 NIL										    )	// [18]  L   Indica pulo de linha ap�s o campo
		
	EndIf
	
	//SIGACTB por item, classe e valor
	if cClasVlA == '1'
		
		oStruct:AddField("TMP_CLVL"									    ,;	// [01]  C   Nome do Campo
		                 "09"									    	,;	// [02]  C   Ordem
		                 "Classe Valor"								    ,;	// [03]  C   Titulo do campo
		                 "Classe Valor"								    ,;	// [04]  C   Descricao do campo
		                 NIL											,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_CLVL","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_CLVL","X3_PICTURE")			,;	// [07]  C   Picture
		                 NIL											,;	// [08]  B   Bloco de Picture Var
		                 NIL											,;	// [09]  C   Consulta F3
		                 .F.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDATUAIS" 									,;	// [12]  C   Agrupamento do campo
		                 NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
		
		oStruct:AddField("TMP_ITEM"					    				,;	// [01]  C   Nome do Campo
		                 "10"							    			,;	// [02]  C   Ordem
		                 "Item"								    		,;	// [03]  C   Titulo do campo
 		                 "Item"									    	,;	// [04]  C   Descricao do campo
		                 NIL											,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_ITEM","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_ITEM","X3_PICTURE")			,;	// [07]  C   Picture
		                 NIL											,;	// [08]  B   Bloco de Picture Var
		                 NIL											,;	// [09]  C   Consulta F3
		                 .F.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDATUAIS" 									,;	// [12]  C   Agrupamento do campo
		                 NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
	EndIf
	
	oStruct:AddField("FILIPROP"									        ,;	// [01]  C   Nome do Campo
	                 "11"	        									,;	// [02]  C   Ordem
	                 "Filial"		        							,;	// [03]  C   Titulo do campo
	                 "Filial"				        					,;	// [04]  C   Descricao do campo
	                 NIL							     				,;	// [05]  A   Array com Help
	                 "C"								     			,;	// [06]  C   Tipo do campo
	                 NIL									    		,;	// [07]  C   Picture
	                 NIL										    	,;	// [08]  B   Bloco de Picture Var
	                 "SM0"										        ,;	// [09]  C   Consulta F3
	                 .T.    											,;	// [10]  L   Indica se o campo � alteravel
	                 NIL	    										,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"     									,;	// [12]  C   Agrupamento do campo
	                 NIL				    							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_N_F_D"    									,;	// [01]  C   Nome do Campo
	                 "12"			     	    						,;	// [02]  C   Ordem
	                 "Nome da Filial"	    	    					,;	// [03]  C   Titulo do campo
	                 "Nome da Filial"				        			,;	// [04]  C   Descricao do campo
	                 NIL									    		,;	// [05]  A   Array com Help
	                 "C"										    	,;	// [06]  C   Tipo do campo
	                 NIL											    ,;	// [07]  C   Picture
	                 NIL    											,;	// [08]  B   Bloco de Picture Var
	                 NIL	    										,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"      								,;	// [12]  C   Agrupamento do campo
	                 NIL				    							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.							    				,;	// [16]  L   Indica se o campo � virtual
	                 NIL								    			,;	// [17]  C   Picture Variavel
	                 NIL									    		)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("CCUSTOPROP"							            ,;	// [01]  C   Nome do Campo
	                 "13"		        								,;	// [02]  C   Ordem
	                 "Centro de Custo"	        						,;	// [03]  C   Titulo do campo
	                 "Centro de Custo"			        				,;	// [04]  C   Descricao do campo
	                 NIL								    			,;	// [05]  A   Array com Help
	                 "C"									    		,;	// [06]  C   Tipo do campo
	                 NIL										    	,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 "FSCTTM"	        								,;	// [09]  C   Consulta F3
	                 .T.				    							,;	// [10]  L   Indica se o campo � alteravel
	                 NIL					    						,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 				        				,;	// [12]  C   Agrupamento do campo
	                 NIL								    			,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL									   		    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL		    								  	,;	// [15]  C   Inicializador de Browse
	                 .T.			    								,;	// [16]  L   Indica se o campo � virtual
	                 NIL				    							,;	// [17]  C   Picture Variavel
	                 NIL					    						)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_CC_D"				            			,;	// [01]  C   Nome do Campo
	                 "14"									        	,;	// [02]  C   Ordem
	                 "Descri��o Centro de Custo"					    ,;	// [03]  C   Titulo do campo
	                 "Descri��o Centro de Custo"    					,;	// [04]  C   Descricao do campo
	                 NIL							    				,;	// [05]  A   Array com Help
	                 "C"	    										,;	// [06]  C   Tipo do campo
	                 NIL		    									,;	// [07]  C   Picture
	                 NIL			    								,;	// [08]  B   Bloco de Picture Var
	                 NIL				    							,;	// [09]  C   Consulta F3
	                 .F.					    						,;	// [10]  L   Indica se o campo � alteravel
	                 NIL						    					,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS"					        			,;	// [12]  C   Agrupamento do campo
	                 NIL									    		,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL										    	,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("DEPTOPROP"		        						,;	// [01]  C   Nome do Campo
	                 "15"						        				,;	// [02]  C   Ordem
	                 "Departamento"						        		,;	// [03]  C   Titulo do campo
	                 "Departamento"								        ,;	// [04]  C   Descricao do campo
	                 NIL		    									,;	// [05]  A   Array com Help
	                 "C"			     								,;	// [06]  C   Tipo do campo
	                 NIL				    							,;	// [07]  C   Picture
	                 NIL					    						,;	// [08]  B   Bloco de Picture Var
	                 "FSSQBM"		    		        				,;	// [09]  C   Consulta F3
	                 .T.								    			,;	// [10]  L   Indica se o campo � alteravel
	                 NIL									    		,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 								        ,;	// [12]  C   Agrupamento do campo
	                 NIL		     									,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL			    								,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL				    							,;	// [15]  C   Inicializador de Browse
	                 .T.					    						,;	// [16]  L   Indica se o campo � virtual
	                 NIL						     					,;	// [17]  C   Picture Variavel
	                 NIL							    				)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("TMP_D_DEPD"								        ,;	// [01]  C   Nome do Campo
	                 "16"										        ,;	// [02]  C   Ordem
	                 "Nome do Departamento"	        					,;	// [03]  C   Titulo do campo
	                 "Nome do Departamento"			        			,;	// [04]  C   Descricao do campo
	                 NIL									    		,;	// [05]  A   Array com Help
	                 "C"										    	,;	// [06]  C   Tipo do campo
	                 NIL											    ,;	// [07]  C   Picture
	                 NIL		    									,;	// [08]  B   Bloco de Picture Var
	                 NIL			    								,;	// [09]  C   Consulta F3
	                 .F.				    							,;	// [10]  L   Indica se o campo � alteravel
	                 NIL					    						,;	// [11]  C   Pasta do campo
	                 "DDPROPOSTOS" 				        				,;	// [12]  C   Agrupamento do campo
	                 NIL								     			,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL									    		,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL										    	,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL										 	    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	//SIGAORG como posto
	if cTipOrgA == '1'
		
		oStruct:AddField("POSTOPROP"							        ,;	// [01]  C   Nome do Campo
		                 "17"										    ,;	// [02]  C   Ordem
		                 "Posto"										,;	// [03]  C   Titulo do campo
		                 "Posto"										,;	// [04]  C   Descricao do campo
		                 NIL											,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_POSTO","X3_TIPO")			    ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_POSTO","X3_PICTURE")		    ,;	// [07]  C   Picture
		                 NIL											,;	// [08]  B   Bloco de Picture Var
		                 "FSRCL2"									    ,;	// [09]  C   Consulta F3
		                 .T.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDPROPOSTOS" 								    ,;	// [12]  C   Agrupamento do campo
		                 NIL										 	,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
		
		oStruct:AddField("DFUNCPROP"       								,;	// [01]  C   Nome do Campo
		                 "18"				        					,;	// [02]  C   Ordem
		                 "Descri��o Cargo"					         	,;	// [03]  C   Titulo do campo
		                 "Descri��o Cargo"							    ,;	// [04]  C   Descricao do campo
		                 NIL										    ,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_DCARGO","X3_TIPO")		        ,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_DCARGO","X3_PICTURE")		    ,;	// [07]  C   Picture
		                 NIL     										,;	// [08]  B   Bloco de Picture Var
		                 NIL	    									,;	// [09]  C   Consulta F3
		                 .F.		     								,;	// [10]  L   Indica se o campo � alteravel
		                 NIL			    							,;	// [11]  C   Pasta do campo
		                 "DDPROPOSTOS" 		    						,;	// [12]  C   Agrupamento do campo
		                 NIL					     					,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL						    				,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL							    			,;	// [15]  C   Inicializador de Browse
		                 .T.								    		,;	// [16]  L   Indica se o campo � virtual
		                 NIL									    	,;	// [17]  C   Picture Variavel
		                 NIL										    )	// [18]  L   Indica pulo de linha ap�s o campo
	EndIf
	
	//SIGACTB por item, classe e valor
	if cClasVlA == '1'
		 
		oStruct:AddField("CLVLPROP"									    ,;	// [01]  C   Nome do Campo
		                 "19"										    ,;	// [02]  C   Ordem
		                 "Classe Valor"								    ,;	// [03]  C   Titulo do campo
		                 "Classe Valor"								    ,;	// [04]  C   Descricao do campo
		                 NIL											,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_CLVL","X3_TIPO")	    		,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_CLVL","X3_PICTURE")	 		,;	// [07]  C   Picture
		                 NIL									 		,;	// [08]  B   Bloco de Picture Var
		                 "CTH"									    	,;	// [09]  C   Consulta F3
		                 .T.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDPROPOSTOS" 								    ,;	// [12]  C   Agrupamento do campo
		                 NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
		
		oStruct:AddField("ITEMPROP"			    						,;	// [01]  C   Nome do Campo
		                 "20"					    					,;	// [02]  C   Ordem
		                 "Item"						    				,;	// [03]  C   Titulo do campo
		                 "Item"							    			,;	// [04]  C   Descricao do campo
		                 NIL								 			,;	// [05]  A   Array com Help
		                 GetSx3Cache("RA_ITEM","X3_TIPO")	    		,;	// [06]  C   Tipo do campo
		                 GetSx3Cache("RA_ITEM","X3_PICTURE")			,;	// [07]  C   Picture
		                 NIL											,;	// [08]  B   Bloco de Picture Var
		                 "CTD"										    ,;	// [09]  C   Consulta F3
		                 .T.											,;	// [10]  L   Indica se o campo � alteravel
		                 NIL											,;	// [11]  C   Pasta do campo
		                 "DDPROPOSTOS" 								    ,;	// [12]  C   Agrupamento do campo
		                 NIL											,;	// [13]  A   Lista de valores permitido do campo (Combo)
		                 NIL											,;	// [14]  N   Tamanho maximo da maior op��o do combo
		                 NIL											,;	// [15]  C   Inicializador de Browse
		                 .T.											,;	// [16]  L   Indica se o campo � virtual
		                 NIL											,;	// [17]  C   Picture Variavel
		                 NIL											)	// [18]  L   Indica pulo de linha ap�s o campo
	EndIf
	
Return oStruct

/*{Protheus.doc} $VWStrRB6
Estutura a ser visualizada referente a grid Tabela Salarial contida na aba Altera��o SAlarial parte inferior esquerda
@type Static function
@author Cris
@since 27/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo Estutura a ser visualizada referente a grid Tabela Salarial contida na aba Altera��o Salarial}
*/
Static Function VWStrRB6()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddField("NIVELATU"								            ,;	// [01]  C   Nome do Campo
	                 "01"											    ,;	// [02]  C   Ordem
	                 Alltrim(GetSx3Cache("RB6_NIVEL","X3_TITULO"))	    ,;	// [03]  C   Titulo do campo
	                 Alltrim(GetSx3Cache("RB6_NIVEL","X3_DESCRIC"))	    ,;	// [04]  C   Descricao do campo
	                 NIL												,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_NIVEL","X3_TIPO")				    ,;	// [06]  C   Tipo do campo
	                 ""												    ,;	// [07]  C   Picture
	                 NIL												,;	// [08]  B   Bloco de Picture Var
	                 NIL												,;	// [09]  C   Consulta F3
	                 .F.												,;	// [10]  L   Indica se o campo � alteravel
	                 NIL												,;	// [11]  C   Pasta do campo
	                 NIL												,;	// [12]  C   Agrupamento do campo
	                 NIL												,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL												,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL												,;	// [15]  C   Inicializador de Browse
	                 .T.												,;	// [16]  L   Indica se o campo � virtual
	                 NIL												,;	// [17]  C   Picture Variavel
	                 NIL												)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("FAIXAATU"							 	            ,;	// [01]  C   Nome do Campo
	                 "02"										        ,;	// [02]  C   Ordem
	                 "Faixa"	    									,;	// [03]  C   Titulo do campo
	                 "Faixa"		    								,;	// [04]  C   Descricao do campo
	                 NIL				    							,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_FAIXA","X3_TIPO")     			,;	// [06]  C   Tipo do campo
	                 NIL									    		,;	// [07]  C   Picture
	                 NIL										    	,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.	    										,;	// [10]  L   Indica se o campo � alteravel
	                 NIL		     									,;	// [11]  C   Pasta do campo
	                 NIL			    								,;	// [12]  C   Agrupamento do campo
	                 NIL				    							,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL					    						,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL						    					,;	// [15]  C   Inicializador de Browse
	                 .T.    											,;	// [16]  L   Indica se o campo � virtual
	                 NIL    											,;	// [17]  C   Picture Variavel
	                 NIL    											)	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("VALORATU"							             	,;	// [01]  C   Nome do Campo
	                 "03"										        ,;	// [02]  C   Ordem
	                 "Valor"							                ,;	// [03]  C   Titulo do campo
	                 "Valor"								 		    ,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_VALOR","X3_TIPO")			        ,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RB6_VALOR","X3_PICTURE")	         	,;	// [07]  C   Picture
	                 NIL											    ,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL											    ,;	// [11]  C   Pasta do campo
	                 NIL											    ,;	// [12]  C   Agrupamento do campo
	                 NIL											    ,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL											    ,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL											    ,;	// [15]  C   Inicializador de Browse
	                 .T.											    ,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL										    	)	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} ${VWStrTMP}
Estutura a ser visualizada referente a grid Tabela Salarial Proporcional tempor�ria contida na aba Altera��o Salarial parte inferior direita
@type Static function
@author Cris
@since 03/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${oStruct}, ${Modelo Estrutura a ser visualizada referente a grid Tabela Salarial Proporcional tempor�ria}
*/
Static Function VWStrTMP()
	
	Local oStruct := FWFormViewStruct():New()
	
	oStruct:AddField("NIVELTMP"									        ,;	// [01]  C   Nome do Campo
	                 "01"										        ,;	// [02]  C   Ordem
	                 "Nivel"					     					,;	// [03]  C   Titulo do campo
	                 "Nivel"							    			,;	// [04]  C   Descricao do campo
	                 NIL									    		,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_NIVEL","X3_TIPO")			        ,;	// [06]  C   Tipo do campo
	                 NIL	     										,;	// [07]  C   Picture
	                 NIL		    									,;	// [08]  B   Bloco de Picture Var
	                 NIL			    								,;	// [09]  C   Consulta F3
	                 .F.				    							,;	// [10]  L   Indica se o campo � alteravel
	                 NIL					    						,;	// [11]  C   Pasta do campo
	                 NIL						    					,;	// [12]  C   Agrupamento do campo
	                 NIL							    				,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL								    			,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL									    		,;	// [15]  C   Inicializador de Browse
	                 .T.										    	,;	// [16]  L   Indica se o campo � virtual
	                 NIL											    ,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("FAIXATMP"								          	,;	// [01]  C   Nome do Campo
	                 "02"							         			,;	// [02]  C   Ordem
	                 "Faixa"								     		,;	// [03]  C   Titulo do campo
	                 "Faixa"									    	,;	// [04]  C   Descricao do campo
	                 NIL											    ,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_FAIXA","X3_TIPO")     			,;	// [06]  C   Tipo do campo
	                 NIL									    		,;	// [07]  C   Picture
	                 NIL										    	,;	// [08]  B   Bloco de Picture Var
	                 NIL											    ,;	// [09]  C   Consulta F3
	                 .F.		    									,;	// [10]  L   Indica se o campo � alteravel
	                 NIL			    								,;	// [11]  C   Pasta do campo
	                 NIL				    							,;	// [12]  C   Agrupamento do campo
	                 NIL					    						,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL						    					,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL							    				,;	// [15]  C   Inicializador de Browse
	                 .T.									    		,;	// [16]  L   Indica se o campo � virtual
	                 NIL										    	,;	// [17]  C   Picture Variavel
	                 NIL											    )	// [18]  L   Indica pulo de linha ap�s o campo
	
	oStruct:AddField("VALORTMP"							             	,;	// [01]  C   Nome do Campo
	                 "03"				        						,;	// [02]  C   Ordem
	                 "Valor Proporcional"		         				,;	// [03]  C   Titulo do campo
	                 "Valor Proporcional"				        		,;	// [04]  C   Descricao do campo
	                 NIL										     	,;	// [05]  A   Array com Help
	                 GetSx3Cache("RB6_VALOR","X3_TIPO")	    	    	,;	// [06]  C   Tipo do campo
	                 GetSx3Cache("RB6_VALOR","X3_PICTURE")   	    	,;	// [07]  C   Picture
	                 NIL									    		,;	// [08]  B   Bloco de Picture Var
	                 NIL										    	,;	// [09]  C   Consulta F3
	                 .F.											    ,;	// [10]  L   Indica se o campo � alteravel
	                 NIL    											,;	// [11]  C   Pasta do campo
	                 NIL	    										,;	// [12]  C   Agrupamento do campo
	                 NIL		     									,;	// [13]  A   Lista de valores permitido do campo (Combo)
	                 NIL			    								,;	// [14]  N   Tamanho maximo da maior op��o do combo
	                 NIL				    							,;	// [15]  C   Inicializador de Browse
	                 .T.					    						,;	// [16]  L   Indica se o campo � virtual
	                 NIL						    					,;	// [17]  C   Picture Variavel
	                 NIL							    				)	// [18]  L   Indica pulo de linha ap�s o campo
	
Return oStruct

/*{Protheus.doc} FSVLSALP
Retorna a valida��o das informa��es de valores referente ao sal�rio
@type Static function
@author Cris
@since 25/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValSal}, ${.T. informa��es de salario v�lidas .F. informa��es n�o v�lidas}
*/
Static Function FSVLSALP()
	
	Local oModAtu  := FWModelActive()
	Local nValSal  := oModAtu:GetModel("SALDETAIL"):GEtValue("SALARIOPROP")
	Local nSalHr   := 0
	Local nValReal := 0
	Local lValSal  := .T.
	
//    MDGatilho(2) // gus
	
	//Validar se o sal�rio proposto esta diferente do  atual
	if nValSal <> 0
		
		//Efetuar diversar valida��es de acordo com a EF
		if SRA->RA_SALARIO <> nValSal
			
			If SRA->RA_SALARIO > nValSal
				
				if oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") == 0
					
					Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_03)", "Para reduzir o sal�rio � necess�rio efetuar a solicita��o atrav�s da Carga Hor�ria!" , 3, 0)
					lValSal	:= .F.
				Else
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de Sal�rio(FSVLSALP_04)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf
				EndIf
			Else
				If oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") <> 0
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_05)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf 
				EndIf
			EndIf
			
		Else
			
			Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_01)", "Informe um sal�rio proposto diferente do atual!" , 3, 0)
			lValSal		:= .F.
			
		EndIf
		
		if lValSal						
			lESalPrp	:= .T. //Indica que existe altera��o salarial			
		Else			
			lESalPrp	:= .F. //Indica que nao existe altera��o salarial			
		EndIf
		
	Else
		
		lESalPrp	:= .F. //Indica que nao existe altera��o salarial
		
	EndIf
	
Return lValSal

/*{Protheus.doc} $FSVLCARP
Valida o Cargo informado e chama rotina para montar tabela salarial
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValCar}, ${.T. cargo informado v�lido .F. cargo N�o v�lido}
*/
Static Function FSVLCARP()
	
	Local oModAtu  := FWModelActive()
	Local cCodCarg := oModAtu:GetModel("CARDETAIL"):GEtValue("CARGOPROP")
	Local lValCar  := .T.
	Local aAreaAtu := {}
	Local aAreaSRJ := {}
	Local nSalSQ3  := 0
	
	if !Empty(cCodCarg)
		
		if cCodCarg <> oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_CARGO")
			
			aAreaAtu	:= SQ3->(GetArea())
			dbSelectArea("SQ3")
			SQ3->(dbSetOrder(1))
			if SQ3->(dbSeek(FwxFilial("SQ3")+cCodCarg))
				
				if  FieldPos("Q3_MSBLQL") > 0 .AND. SQ3->Q3_MSBLQL == '1'
					
					Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_02)", "Cargo bloqueado para uso, contate o respons�vel pela manuten��o de cadastro de Cargos!" , 3, 0)
					lValCar	:= .F.
					
				Else
					
					aAreaSRJ	:= SRJ->(GetArea())
					dbSelectArea("SRJ")
					SRJ->(dbSetOrder(4))//RJ_FILIAL+RJ_CARGO
					if SRJ->(dbSeek(FwxFilial("SRJ")+cCodCarg))
						
						if  FieldPos("RJ_MSBLQL") > 0 .AND. SRJ->RJ_MSBLQL == '1'
							
							Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_04)", "Fun��o bloqueado para uso, contate o respons�vel pela manuten��o de cadastro da fun��o!" , 3, 0)
							lValCar	:= .F.
							
						Else
							
							nSalSQ3	:= SRJ->RJ_SALARIO
							
						EndIf
						
					Else
						
						dbSelectArea("SRJ")
						SRJ->(dbSetOrder(1))//RJ_FILIAL+RJ_FUNCAO
						if SRJ->(dbSeek(FwxFilial("SRJ")+cCodCarg))
							
							if  FieldPos("RJ_MSBLQL") > 0 .AND. SRJ->RJ_MSBLQL == '1'
								
								Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_04)", "Fun��o bloqueado para uso, contate o respons�vel pela manuten��o de cadastro da fun��o!" , 3, 0)
								lValCar	:= .F.
								
							Else
								
								nSalSQ3	:= SRJ->RJ_SALARIO
								
							EndIf
							
						Else
							
							Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_05)", "Deve-se associar o cargo a uma fun��o!" , 3, 0)
							lValCar	:= .F.
						EndIf
					EndIf
					RestArea(aAreaSRJ)
				EndIf
			Else
				
				Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_03)", "Informe um cargo existente!" , 3, 0)
				lValCar	:= .F.
			EndIf
			
			RestArea(aAreaAtu)
			
			if lValCar
				
				//Se n�o esta sendo chamada da fun��o antes da grava��o
				If !IsInCallStack("F00504VL")
					
					//Verifica se por padr�o deve-se  alterar o sal�rio automaticamente
					AtCarSal(nSalSQ3,lValCar)
					
				EndIf
				
				if lValCar		
					lECarPrp	:= .T. //Indica que existe altera��o salarial					
				EndIf
			EndIf
		Else
			
			Help("",1, "Help", "Valida��o da Cargo/Fun��o(FSVLCARP_01)", "Informe um cargo diferente do atual!" , 3, 0)
			lValCar	:= .F.
		EndIf
	Else
		
		lECarPrp	:= .F. //Indica que nao existe altera��o salarial
	EndIf
	
Return lValCar

/*{Protheus.doc} ValPosto
Valida se o posto de destino possui vaga para a Filial/Cargo/Centro de custo e Departamento relacionados na solicita��o.
O retorno das informa��es podem ser usadas para outras finalidades, como comparar o numero de solicita��es em aberto para
o mesmo tipo de solicita��o com a quantidade de vagas dispon�veis.
@type Static Function
@author Cris
@since 04/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${array}, ${nQtdePost= Qtde. dispon�vel,
cFilAt=filial de Destino,
cCCAt=Centro de Custo de Destino,
cDepto=Departamento de Destino,
cCodCarg= Cargo de Destino}
*/
Static Function ValPosto()
	
	Local oModAtu   := FWModelActive()
	Local cDepNovo  := oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")
	Local cFilNova  := oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")
	Local cCCNovo   := oModAtu:GetModel("TRFDETAIL"):GEtValue("CCUSTOPROP")
	Local cCargNov  := oModAtu:GetModel("CARDETAIL"):GEtValue("CARGOPROP")
	Local cPostNov  := oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP")
	Local cDepto    := iif(Empty(cDepNovo),oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_DEPTOA") ,cDepNovo)
	Local cFilAt    := iif(Empty(cFilNova),oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_FILIAL") ,cFilNova)
	Local cCCAt     := iif(Empty(cCCNovo),oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_CCATU") ,cCCNovo)
	Local cCodCarg  := iif(Empty(cCargNov),oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_CARGO"),cCargNov)
	Local cQry      := ''
	Local nQtdePost := 0
	Local cTabAtu   := GetNextAlias()
	Local lLibPst   := SuperGetMv("FS_BLQSOL",,.F.)
	Local _cMsgRet	:= "" //7780516 - Thais Paiva
	
	cQry	:=  "	SELECT (RCL_NPOSTO-RCL_OPOSTO) AS QTDEDISPONIVEL "+CRLF
	cQry	+=  "		FROM "+RetSqlName("RCL")+" "+CRLF
	cQry	+=  "		WHERE RCL_FILIAL = '"+iif(!Empty(FwxFilial("RCL")),cFilAt,FwxFilial("RCL"))+"' "+CRLF
	cQry	+=  "		  AND RCL_DEPTO = '"+cDepto+"' "+CRLF
	cQry	+=  "		  AND RCL_CARGO IN ('','"+cCodCarg+"')"+CRLF
	If lETrfPrp
		cQry	+=  "		  AND RCL_CC	= '"+cCCAt+"' "+CRLF
	EndIf
	If !(EMPTY(cPostNov))
		cQry	+=  "		  AND RCL_POSTO	= '"+ALLTRIM(cPostNov)+"' "+CRLF
	EndIf
	cQry	+=  "		  AND D_E_L_E_T_ = ''"+CRLF
	cQry	+=  "		  AND ("+CRLF
	cQry	+=  "		  		RCL_DTFIM >= '"+Dtos(dDataBase)+"' OR "+CRLF
	cQry	+=  "		  		RCL_DTFIM = ' '"+CRLF
	cQry	+=  "		   )"+CRLF
	cQry	+=  "		  AND RCL_STATUS NOT IN('4')"+CRLF
	
	cQry := ChangeQuery(cQry)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTabAtu,.T.,.T.)
	
	if !(cTabAtu)->(Eof())
		
		if (cTabAtu)->QTDEDISPONIVEL - U_F0500314(cDepto, cFilNova, cPostNov) <= 0
			If !lLibPst
				lValPosto	:= .F.
			Else
				//MsgAlert("Este posto est� ocupado/reservado. A solicita��o ser� processada, mas o colaborador ser� movimentado somente ap�s a desocupa��o do posto.")
				MsgAlert("Este posto est� ocupado. Caso n�o realize a adequa��o, a quantidade de colaboradores existentes ser� maior que a quantidade prevista.")
				lValPosto	:= .T.
			EndIf			
		Else
			
			nQtdePost	:= (cTabAtu)->QTDEDISPONIVEL
			lValPosto	:= .T.
			
		EndIf
		
	Else
		
		lValPosto	:= .F.
		
	EndIf
	
	if !lValPosto
		//Help("",1, "Help", "Valida��o da Posto(ValPosto_01)", "Para o cargo "+cCodCarg+", departamento "+cDepto+" e filial "+cFilAt+" n�o existe posto dispon�vel!" , 3, 0) 7780516 - Thais Paiva
		_cMsgRet := "Valida��o da Posto(ValPosto_01) - Para o cargo "+cCodCarg+", departamento "+cDepto+" e filial "+cFilAt+" n�o existe posto dispon�vel!"
	EndIf
	
	(cTabAtu)->(dbCloseArea())
	
Return _cMsgRet //{nQtdePost,cFilAt,cCCAt,cDepto,cCodCarg} 7780516 - Thais Paiva

/*{Protheus.doc} AtCarSal
Verifica se atualiza o sal�rio proposto de acordo com o Cargo e a Carga hor�ria
@type Static function
@author Cris
@since 03/11/2016
@param nSalSQ3, num�rico, (Valor do Sal�rio contido na tabela de Cargo)
@param lValCar, ${l�gico}, (.T. v�lido e .F. n�o v�lido)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
@see http://tdn.totvs.com/pages/releaseview.action;jsessionid=DB6F0D59797BF92D3C43400F2F276B98?pageId=233760654
*/
Static Function AtCarSal(nSalSQ3,lValCar)
	
	Local cAlCgSlA := GetMV("MV_ALTSAL")//Verifica se altera  o sal�rio automaticamente conforme cadastro de fun��o ou deixa  informar manualmente
	Local oModAtu  :=	FWModelActive()
	Local oView    := Nil
	
	//Se Sim (MV_ALTSAL) atualiza a aba altera��o salarial conforme o valor contido no cadastro de fun��o
	if cAlCgSlA == 'S'
		
		if !(oModAtu:GetModel("SALDETAIL"):SetValue("SALARIOPROP",nSalSQ3))
			
			Help("",1, "Help", "Valida��o da Cargo/Fun��o/Sal�rio(AtCarSal_01)",;
				"N�o foi poss�vel alterar a aba Altera��o Salarial!"+;
				" Verifique se no cadastro de fun��o existe informa��o de sal�rio (MV_ALTSAL = 'S')." , 3, 0)
			lValCar	:= .F.
			
		EndIf
		
	Else
		
		//Monto tabela salarial tempor�ria e se aplic�vel atualiza o campo sal�rio  proposto
		if !lETrfPrp .AND. MtSALHor(oModAtu)
			
			if oModAtu:GetModel("SALDETAIL"):GetValue("SALARIOPROP") == 0
				
				oModAtu:GetModel("SALDETAIL"):SetValue("SALARIOPROP",oModAtu:GetModel("TMPDETAIL"):GetValue("VALORTMP",Val(oModAtu:GetModel("SALDETAIL"):GetValue("TMP_FAIXAT"))))
				
			EndIf
			
		EndIf
		
	EndIf
	
Return lValCar

/*{Protheus.doc} MtSALHor
Consulto a carga hor�ria atual e/ou proposta e efetuo a proporcionalidade calculando os valores a serem sugeridos com base na
tabela salarial atual
@type static function
@author Cris
@since 03/11/2016
@param oModAtu, objeto, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lTabPnal}, ${.T. a tabela proporcional foi calculada, portanto existe, .F. Tabela n�o existe}
*/
Static Function MtSALHor(oModAtu)
	
	Local nCrgHrPp	:=  oModAtu:GetModel("HORDETAIL"):GetValue("HMESPROP")//Carga hor�ria proposta
	Local nCrgHrAt	:=  oModAtu:GetModel("HORDETAIL"):GetValue("TMP_H_M_AT") //Carga hor�ria Atual
	Local nSalPnal	:= 0
	Local nPropSal	:= 0
	Local nFaixa	:= 1
	Local nFxTabAt	:= 0
	Local lTabPnal	:= .F.
	
	//Somente se a carga hor�ria foi alterada e for diferente da Carga horaria padr�o 220
	if nCrgHrPp <> 0 .AND. nCrgHrPp <> nCrgHrAt .AND. nCrgHrPp <= 220
		//Caso tenha sido informado uma  carga hor�ria diferente da atual, efetua a proporcionalidade
		
		nFxTabAt	:= oModAtu:GetModel("RB6DETAIL"):Length()//Carrego a quantidade de faixas existente
		
		if nFxTabAt > 0 .AND. oModAtu:GetModel("RB6DETAIL"):GetValue("VALORATU",1) <> 0
			
			//Busco o percentual de toler�ncia
			aAreaRCA	:= RCA->(GetArea())

			//Monto a tabela tempor�ria de acordo com o numero de faixas existentes na tabela atual associada ao funcion�rio
			While nFaixa < nFxTabAt+1
				
				nSalPnal	:= Round((oModAtu:GetModel("RB6DETAIL"):GetValue("VALORATU",nFaixa)*nCrgHrPp)/nCrgHrAt,2)
				
				if nFaixa > 1 .AND. nFxTabAt <> oModAtu:GetModel("TMPDETAIL"):Length()
					
					oModAtu:GetModel("TMPDETAIL"):AddLine()
					
				EndIf
				
				oModAtu:GetModel("TMPDETAIL"):GoLine(nFaixa)
				
				oModAtu:GetModel("TMPDETAIL"):SetValue("NIVELTMP",oModAtu:GetModel("RB6DETAIL"):GetValue("NIVELATU",nFaixa))
				oModAtu:GetModel("TMPDETAIL"):SetValue("FAIXATMP",oModAtu:GetModel("RB6DETAIL"):GetValue("FAIXAATU",nFaixa))
				oModAtu:GetModel("TMPDETAIL"):SetValue("VALORTMP",nSalPnal)
				
				nFaixa	:=  nFaixa  +1
				
			EndDo
			
			//Posiciono na primeira linha para garantir uma exibi��o correta
			oModAtu:GetModel("TMPDETAIL"):GoLine(1)
			
			lTabPnal	:= .T.
			
			RestArea(aAreaRCA)
		
		EndIf
		
	Else
		
		lTabPnal	:= .F.
		
	EndIf
	//Atualiza com a mesma faixa salarial da tabela atual para demonstrar que a base 220 mantem os valores
	if lTabPnal .AND. nCrgHrPp == 220
		
		nFxTabAt	:= oModAtu:GetModel("TMPDETAIL"):Length()
		
		While nFaixa < nFxTabAt
			
			oModAtu:GetModel("TMPDETAIL"):GoLine(nFaixa)
			oModAtu:GetModel("TMPDETAIL"):SetValue("VALORTMP",0)
			nFaixa	:= nFaixa +1
			
		EndDo
		
		oModAtu:GetModel("TMPDETAIL"):GoLine(1)
		
	EndIf
	
Return lTabPnal

/*{Protheus.doc} FSVLHORP
Valida a Carga hor�ria
@type Static function
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValHor}, ${.T. dados v�lidos .F. dados n�o v�lidos}
*/
Static Function FSVLHORP(nOpc)
	
	Local oModAtu  := FWModelActive()
	Local cCargHor := oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP")
	Local cCargSem := oModAtu:GetModel("HORDETAIL"):GEtValue("HSEMPROP")
	Local cCargDia := oModAtu:GetModel("HORDETAIL"):GEtValue("HDIAPROP")
	Local lValHor  := .T.
	
	Default nOpc	:= 0 
	//Valida a carga hor�ria M�s
	if !Empty(cCargHor)
		
		//Valida se foi informado uma carga hor�ria maior que a permitida por lei
		if oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") > 220
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_01)",+;
				" O valor informado ultrapassa da quantidade de horas (220 horas) permitida." , 3, 0)
			lValHor	:= .F.
			
		Elseif  oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") < 0
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_07)",+;
				" Valor m�s negativo n�o � permitido." , 3, 0)
			lValHor	:= .F.
			
		EndIf
		
	EndIf
	
	//Valida a carga hor�ria Semana
	if !Empty(cCargSem)
		
		if oModAtu:GetModel("HORDETAIL"):GEtValue("HSEMPROP") > 44
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_02)",+;
				" O valor informado ultrapassa da quantidade de horas (44 horas) permitida." , 3, 0)
			lValHor	:= .F.
			
		Elseif oModAtu:GetModel("HORDETAIL"):GEtValue("HSEMPROP") < 0
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_05)",+;
				" Valores negativos n�o s�o permitidos." , 3, 0)
			lValHor	:= .F.
			
		EndIf

	EndIf
	
	//Valida a carga horaria por dia
	if !Empty(cCargDia)
		
		if oModAtu:GetModel("HORDETAIL"):GEtValue("HDIAPROP") > 24
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_03)",+;
				" O valor informado ultrapassa da quantidade de horas (24 horas) permitida." , 3, 0)
			lValHor	:= .F.
			
		Elseif oModAtu:GetModel("HORDETAIL"):GEtValue("HDIAPROP") < 0
			
			Help("",1, "Help", "Valida��o da Carga Hor�ria(FSVLHORP_06)",+;
				" Valor dia negativo n�o � permitido." , 3, 0)
			lValHor	:= .F.
			
		Endif
		
	EndIf

	cCargHor := If(ValType( cCargHor) == "N", cCargHor, Val(cCargHor))
	
	if lValHor .AND. cCargHor > 0 .AND. cCargHor <= 220 // .AND. cCargSem > 0 .AND. cCargDia > 0
		
			//nSal := Round((SRA->RA_SALARIO / SRA->RA_HRSMES),2) * cCargHor
			nSal := (SRA->RA_SALARIO / SRA->RA_HRSMES) * cCargHor
			
			AtCarSal(nSal,.T.) //Atualizado o sal�rio de forma  proporcional
		
			lEHorPrp	:= .T. //Indica que existe altera��o salarial
		
	Else
			lEHorPrp	:= .F. //Indica que nao existe altera��o salarial
		
	EndIf
	If lValHor .And. nOpc == 1
		AVISO("Aviso", "Para os casos em que houver ajuste no sal�rio hora, analisar o campo sal�rio proposto na aba �Altera��o Salarial�", { "Ok"}, 1) 
	EndIf
	
Return lValHor

/*{Protheus.doc} FSVLTURP
V�lida os dados da  Troca de Turno
@type Static function
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function FSVLTURP()
	
	Local oModAtu  := FWModelActive()
	Local cFilDes  := FwxFilial("SR6")
	Local cCodTur  := oModAtu:GetModel("TURDETAIL"):GEtValue("TURNOPROP")
	Local lValTur  := .T.
	Local aAreaAtu := {}
	
	//Pego a filial de destino
	if !Empty(cFilDes) .AND. len(Alltrim(cFilDes)) > 4 //4 primeiras posi��es: Empresa+unidade de neg�cio
		
		iIf(Empty(oModAtu:GetModel("TRFDETAIL"):GetValue("FILIPROP")),cFilDes := oModAtu:GetModel("TRFDETAIL"):GetValue("TMP_FILIAL"), cFilDes:= oModAtu:GetModel("TRFDETAIL"):GetValue("FILIPROP"))
		
	EndIf
	
	//Valida o Turno informado
	if !Empty(cCodTur)
		
		if cCodTur == oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_TURNAT")
			
			Help("",1, "Help", "Valida��o do Turno(FSVLTURP_03)","Informe um turno diferente do atual." , 3, 0)
			lValTur	:= .F.
			
		Else
			
			aAreaAtu	:= SR6->(GetArea())
			
			dbSelectArea("SR6")
			SR6->(dbSetOrder(1))
			if SR6->(dbSeek(cFilDes+cCodTur))
				
				if  FieldPos("R6_MSBLQL") > 0 .AND. SR6->R6_MSBLQL == '1'
					
					Help("",1, "Help", "Valida��o do Turno(FSVLTURP_02)","Este turno esta bloqueado para uso." , 3, 0)
					lValTur	:= .F.
					
				Else
					
					if oModAtu:GetModel("HORDETAIL"):GetValue("HMESPROP") == 0
						
						if ! MsgYesNo("A carga hor�ria de ("+Transform(oModAtu:GetModel("HORDETAIL"):GetValue("TMP_H_M_AT"),"@ 999.9999")+") ser� mantida?","Aten��o")
							
							if !(oModAtu:GetModel("HORDETAIL"):SetValue("HMESPROP",oModAtu:GetModel("HORDETAIL"):GetValue("TMP_H_M_AT")))
								
								Help("",1, "Help", "Atualiza��o Autom�tica(FSVLTURP_04)","N�o foi poss�vel atualizar a Carga Hor�ria a informe manualmente." , 3, 0)
								
							EndIf
						EndIf
					EndIf
				EndIf
				
				RestArea(aAreaAtu)
			Else
				
				Help("",1, "Help", "Valida��o do Turno(FSVLTURP_01)","Informe um turno de trabalho existente." , 3, 0)
				lValTur	:= .F.
			EndIf
		EndIf		
	EndIf
	
	if lValTur .AND. !Empty(cCodTur)				
		lETurPrp	:= .T. //Indica que existe altera��o salarial
	Else	
		lETurPrp	:= .F. //Indica que nao existe altera��o salarial		
	EndIf
	
Return lValTur

/*{Protheus.doc} FSVLTRFP
Valida��o da Transfer�ncia
@type Static function
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValTrf}, ${.T. a transfer�ncia esta valida e .F. n�o esta v�lida}
*/
Static Function FSVLTRFP(cCampo)
	
	Local oModAtu  := FWModelActive()
	Local cFilTrf  := oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")
	Local cCCTrf   := oModAtu:GetModel("TRFDETAIL"):GEtValue("CCUSTOPROP")
	Local cDepTrf  := oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")
	Local cCargSRA := oModAtu:GetModel("CARDETAIL"):GetValue("TMP_CARGO")
	Local cCargPrp := oModAtu:GetModel("CARDETAIL"):GetValue("CARGOPROP")
	Local cPostTrf := ""
	Local lValTrf  :=	.F.
	Local cFilCTT  := IIf(Empty(FwxFilial("CTT")),FwxFilial("CTT"),iif(len(Alltrim(FwxFilial("CTT")))<=4,FwxFilial("CTT"),IIf(!Empty(cFilTrf),cFilTrf,SRA->RA_FILIAL)))
	Local cFilSQB  := IIf(Empty(FwxFilial("SQB")),FwxFilial("SQB"),iif(len(Alltrim(FwxFilial("SQB")))<=4,FwxFilial("SQB"),IIf(!Empty(cFilTrf),cFilTrf,SRA->RA_FILIAL)))
	Local cFilRCL  := IIf(Empty(FwxFilial("RCL")),FwxFilial("RCL"),iif(len(Alltrim(FwxFilial("RCL")))<=4,FwxFilial("RCL"),IIf(!Empty(cFilTrf),cFilTrf,SRA->RA_FILIAL)))
	Local aAreaAtu := {}
	Local lBntConf := IsInCallStack("F00504VL")
	Local cBlqSlTf := GetMV('FS_BLQSLTF')
	Local lLibPst  := SuperGetMv("FS_BLQSOL",,.F.)
	
	Default cCampo := ""
	
	If cTipOrgA == '1'
		cPostTrf  :=  oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP")
	EndIf
	
	//Bloqueia a Solicita��o de uma  transferencia com a altera�a� de sal�rio.
	if cBlqSlTf == 'S' .AND. (!Empty(cFilTrf) .OR. !Empty(cCCTrf) .OR. !Empty(cDepTrf) .OR. !Empty(cPostTrf))
		
		//Verifica se ocorreu altera��o salarial, se sim avisa e exclui as informa��es
		if !Empty(oModAtu:GetModel("SALDETAIL"):GetValue(" SALARIOPROP"))
			
			Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_01)", "N�o � permitido alterar sal�rio quando existe movimenta��o tipo transfer�ncia. O sal�rio proposto ser� zerado!" , 3, 0)
			
			oModAtu:GetModel("SALDETAIL"):SetValue(" SALARIOPROP",0)
			oModAtu:GetModel("SALDETAIL"):SetValue(" TMP_VLSALA",0)
			oModAtu:GetModel("SALDETAIL"):SetValue(" TMP_PERCSA",0)
			oModAtu:GetModel("SALDETAIL"):SetValue(" MOTALTSAL",'')
			oModAtu:GetModel("SALDETAIL"):SetValue(" TMP_D_MOT",'')
			
		EndIf
		
		//Bloqueia o Modelo da Altera��o Salarial
		MtBCMod(oModAtu,{"SALDETAIL"},{||.F.})
		
	Else
		
		//Desbloqueia o Modelo da Altera��o Salarial
		MtBCMod(oModAtu,{"SALDETAIL"},{||.T.})
	EndIf
	
	If cCampo == "FILIAL"
		
		//V�lido a Filial
		if !Empty(cFilTrf)
			
			dbSelectArea("SM0")
			SM0->(dbSetOrder(1))
			If !(lValTrf := SM0->(dbSeek(cEmpAnt+cFilTrf)))				
				Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_03)", "Informe uma filial existente!" , 3, 0)
				lValTrf	:= .F.
			Else
				lValTrf	:=	.T.	
			EndIf
			
		EndIf

	ELSEIF cCampo == "CENTROC"
		
		//V�lido o Centro de Custo
		If !Empty(cCCTrf)
			
			aAreaAtu	:= CTT->(GetArea())
				
			dbSelectArea("CTT")
			CTT->(dbSetOrder(1))
			If !(CTT->(dbSeek(cFilCTT+cCCTrf)))
					
				Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_04)", "Informe uma Centro de Custo existente!" , 3, 0)
				lValTrf	:= .F.
					
			Else
					
				If CTT->CTT_DTEXSF <> ctod('//') .AND. CTT->CTT_DTEXSF <= MsDate()
						
					Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_05)", "Centro de Custo bloqueado!" , 3, 0)
					lValTrf	:= .F.
				Else
					lValTrf	:=	.T.					
				EndIf
					
				If CTT->CTT_CLASSE == '1'
						
					Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_06)", "Selecione um centro de custo anal�tico!" , 3, 0)
					lValTrf	:= .F.
				Else
					lValTrf	:=	.T.
				EndIf
			
			EndIf
				
			RestArea(aAreaAtu)
			
		EndIf
		
	ELSEIF cCampo == "DEPTO"
		
		//V�lida o Departamento
		If !Empty(cDepTrf)
			
			aAreaAtu:= SQB->(GetArea())
			
			dbSelectArea("SQB")
			SQB->(dbSetORder(1))
			If !(SQB->(dbSeek(cFilSQB+cDepTrf)))
			
				Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_07)", "Informe um Departamento existente!" , 3, 0)
				lValTrf	:= .F.
					
			Else
			
				If FieldPos("QB_MSBLQL") > 0 .AND. SQB->QB_MSBLQL == '1'
						
					Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_08)", "Departamento bloqueado!" , 3, 0)
					lValTrf	:= .F.
				Else
					lValTrf	:=	.T.
				EndIf
			
			EndIf
			
		EndIf
		
	ELSEIF cCampo == "POSTOD"
		
		If !Empty(cPostTrf)
			
			If Empty(cDepTrf)				
				cDepTrf := oModAtu:GetModel("TRFDETAIL"):GetValue("TMP_DEPTOA")
			EndIf
			
			nTotal := U_F0500314(cDepTrf, cFilRCL, cPostTrf)
			
			dbSelectArea("RCL")
			RCL->(dbSetORder(1))//RCL_FILIAL, RCL_DEPTO, RCL_POSTO, R_E_C_N_O_, D_E_L_E_T_
			If !RCL->(dbSeek(cFilRCL + cDepTrf + cPostTrf))
				
				Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_10)", "Informe um posto existente!" , 3, 0)
				//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva					
				lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
	//			lValTrf	:= .F.
				
			ElseIf (RCL->RCL_NPOSTO - RCL->RCL_OPOSTO) == 0
				
				If !lLibPst
					Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "Este posto esta totalmente ocupado!" , 3, 0)
					//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva	
					lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
//					lValTrf	:= .F.
				Else
					//Se o Cargo Do Posto proposto for diferente
					If Empty(cCargPrp)
						If RCL->RCL_CARGO != cCargSRA
							Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "O cargo do posto � diferente do cargo do funcion�rio!" , 3, 0)
							//lValTrf	:= .F.
							//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva					
							lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
						Else                                                          
							lValTrf	:=	.T.
						EndIf
					Else
						If RCL->RCL_CARGO != cCargPrp
							Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "O cargo do posto � diferente do cargo proposto!" , 3, 0)
							//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva					
							lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
							//lValTrf	:= .F.					
						Else
							lValTrf	:=	.T.
						EndIf
					EndIf
				EndIf	
				
			ElseIf (RCL->RCL_NPOSTO <= (RCL->RCL_OPOSTO + nTotal)) 
				
				If !lLibPst
					Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "Existe solicita��es vinculadas a esse posto, Favor verificar." , 3, 0)
					//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva					
					lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
				Else
					lValTrf	:= .T.				
				EndIf
			Else
				//Se o Cargo Do Posto proposto for diferente
				If Empty(cCargPrp)
					If RCL->RCL_CARGO != cCargSRA
						Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "O cargo do posto � diferente do cargo do funcion�rio!" , 3, 0)    
						//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva				
						lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
						//lValTrf	:= .F.
					Else
						lValTrf	:=	.T.
					EndIf
				Else
					If RCL->RCL_CARGO != cCargPrp
						Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_11)", "O cargo do posto � diferente do cargo proposto!" , 3, 0)       
						//oModAtu:GetModel("TRFDETAIL"):SetValue("POSTOPROP",'') 7780516 - Thais Paiva				
						lValTrf	:= .T. //Alterado para .T. para n�o exibir a mensagem de Consteudo Invalido, devido ao retorno como .F.. Por este motivo limpo a caixa de texto acima.
						//lValTrf	:= .F.					
					Else
						lValTrf	:=	.T.
					EndIf
				EndIf
				
			EndIf
			
		Else
			If !lBntConf
				lValTrf	:=	.T.
			EndIf		
		EndIf
	
	ENDIF
	
	//Bot�o Cofirmar
	If lBntConf
		
		//Classe Valor
		if cClasVlA == '1'
			
			If Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("ITEMPROP")) .OR. Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("CLVLPROP"))				
				Help("",1, "Help", "Valida��o da Transfer�ncia(FSVLTRFP_09)", "Obrigat�rio preencher o Item e a Classe Valor!" , 3, 0)
				lValTrf	:= .F.
			Else
				lValTrf	:= .T.
			EndIf
		Endif
		
	EndIf
	
	If lValTrf
		lETrfPrp	:= .T. //Indica que existe Transferencia
	Else
		lETrfPrp	:= .F. //Indica que nao existe Transferencia
	EndIf
	
Return lValTrf

/*{Protheus.doc} FS05EXIS
Se existe solicita��o em aberto para a matricula informada
@type Static function
@author Cris
@since 01/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lNExiSol}, ${.T. n�o existe .F. existe}
*/
Static Function FS05EXIS()
	
	Local lNExiSol := .T.
	Local cQryRH3  := ''
	Local cTabAtu  := GetNextAlias()
	Local aMatInc  := {}
	Local cFilFun  := (TSRA)->RA_FILIAL // (oBrowse:Alias())->RA_FILIAL // Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist
	Local cMatFun  := (TSRA)->RA_MAT    // (oBrowse:Alias())->RA_MAT    // Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist
	Local cNomeFn  := (TSRA)->RA_NOME   // (oBrowse:Alias())->RA_NOME   // Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist

	
	//Carrego informa��es do usu�rio logado
	aMatInc	:= U_GetInfMat()
	
	If !Empty(aMatInc[02])
		
		If aMatInc[01]+aMatInc[02] <> cFilFun+cMatFun
			
			cQryRH3	:= "SELECT RH3_CODIGO "+CRLF
			cQryRH3	+= " FROM "+RetSqlName("RH3")+" (NOLOCK)"+CRLF
			cQryRH3	+= " WHERE RH3_FILIAL = '"+cFilFun+"'"+CRLF
			cQryRH3	+= " AND RH3_MAT = '"+cMatFun+"'"+CRLF
			cQryRH3	+= " AND RH3_STATUS NOT IN('2','3')"+CRLF
			cQryRH3	+= " AND RH3_XTPCTM = '006'"+CRLF
			cQryRH3	+= " AND D_E_L_E_T_ = ' '"+CRLF
			
			cQryRH3 := ChangeQuery(cQryRH3)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryRH3),cTabAtu,.T.,.T.)
			
			if !(cTabAtu)->(Eof())
				
				Help("",1, "Help", "Valida��o de Abertura(FS05EXIS_01)", "Para este funcion�rio ";
					+cFilFun+"-"+cMatFun+"-"+cNomeFn+" existe solicita��o em aberto, deve-se aguardar o encerramento da mesma. Numero  da Solicita��o: "+(cTabAtu)->RH3_CODIGO , 3, 0)
				
				lNExiSol	:= .F.
				
			EndIf
			
			(cTabAtu)->(dbCloseArea())
			
		Else
			Help("",1, "Help", "Aten��o", "Usu�rio n�o tem permiss�o para realizar movimenta��o para si pr�prio." , 3, 0)
			lNExiSol := .F.
		EndIf
		
	Else
		lNExiSol := .F.
	EndIf
	
Return lNExiSol

/*{Protheus.doc} F00504VL
valida��o total no bot�o Confirmar
@type Static function
@author Cris
@since 28/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lSolicVal}, ${.T. solicita��o valida .F. solicita��o n�o valida}
*/
Static Function F00504VL()
	
	Local oModAtu   := FWModelActive()
	Local lSolicVal := .T.
	Local lSalProp  := FSVLSALP()
	Local cSalVali  := " "
	Local lCarProp  := FSVLCARP()
	Local lTurProp  := FSVLTURP()
	Local lHorProp	:= FSVLHORP() // ticket n� 2669524 [AMS] - Paulo Dias - 11/05/2018
	Local lTrfProp  := FSVLTRFP("POSTOD")
	Local cTitulo   := "Motivo de inclus�o"
	Local cEscalm   := oModAtu:GetModel("SALDETAIL"):GetValue("TMP_ESCL")

	aMotivo := {}
	
	//Se existe altera��o salarial, valida se foi informado o motivo
	if lESalPrp .AND. lSalProp
		
		if !(lSolicVal := MOTALTSL())
			
			cSalVali := "Inconsist�ncias na altera��o salarial: Informe o motivo da  altera��o.(Para altera��o exclusiva de carga horaria e Troca de Turno informar o motivo '013')"
			
		EndIf
		
	EndIf
	
	//Se existe altera��o de cargo, valida se foi informado o motivo.
	//poss�vel cen�rio: quando existir transfer�ncia
	if lSolicVal .AND. lECarPrp .AND. lCarProp
		
		if !(lSolicVal := MOTALTCG())
			
			cSalVali := cSalVali + " Inconsist�ncias na altera��o de cargo: Informe o motivo da altera��o.(Para altera��o exclusiva de carga horaria e Troca de Turno informar o motivo '013')"
			
		EndIf
		
	EndIf
	
	if lSolicVal .AND. !lETurPrp .AND. lEHorPrp
		
		cSalVali  := "Ao solicitar a altera��o de Carga Hor�ria � necess�rio alterar o turno de trabalho."
		lSolicVal := .F.
		
	EndIf
	
	if lETrfPrp .AND. !lTrfProp
		
		cSalVali  := "Verifique as informa��es para a transfer�ncia."
		lSolicVal := .F.
		
	EndIf
	
	if !lETrfPrp .AND. lECarPrp
		
		cSalVali  := "Para alterar o Cargo � necess�rio tamb�m realizar uma transfer�ncia de posto."
		lSolicVal := .F.
		
	EndIf
	
	//Verifico se existe solicita��o de posto em aberto e  se existe se o n�mero de solicita�oes ultrapassa o numero disponivel de posto
	if lSolicVal .AND. lETrfPrp//(lECarPrp .OR. lETrfPrp)
		
		//ValPosto()//Verifica se existe disponibilidade do posto 7780516 - Thais Paiva
		cSalVali := ValPosto()
		if lValPosto
			
			//U_F0060101() requisito N005 Indicadores
			lSolicVal := .T.
			
		Else
			
			//In�cio - 7780516 - Thais Paiva
			If !Empty(Alltrim(cSalVali)) 
				lSolicVal := .F.
			Else
			//Fim - 7780516 - Thais Paiva
				If !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")) .OR. !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")) .OR. !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP"))
					cSalVali  := "N�o existe posto dispon�vel para as informa��es de altera��o."
					lSolicVal := .F.
				EndIf
			EndIf //7780516 - Thais Paiva
			
		EndIf
		
	EndIf
	
	if lSolicVal
		
		if lESalPrp .And. !Empty(GetMv("FS_PSALSUP",,15)) .And. oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_PERCSA") >= GetMv("FS_PSALSUP",,15)
			
			cSubGrp := GetMv("FS_VSALSUP") //C�digo do SubGrupo quando ultrapassar o limite definido de percentual para o aumento salarial
			
		Else
			
			lSolicVal := SelecU04(cEscalm,@cSalVali) //Seleciona o Codigo do SubGrupo
			
		EndIf
		
		If lSolicVal .AND. Empty(cSubGrp) //verificar
			
			cSalVali  := 'N�o localizado o c�digo do SubGrupo para este tipo de solicita��o. Verifique a tabela U004.'
			lSolicVal := .F.
			
		EndIf
		
	EndIf
	
	If !lSolicVal
		
		Help(,1, "Help", "Valida��o da solicita��o(F00504VL_01)", "Solicita��o n�o ser� gravada! "+cSalVali , 3 , 0)
		
	EndIf
	
	If lSolicVal
		aMotivo := U_Motivo(cTitulo)
		If !(aMotivo[1])
			oModAtu:SetErrorMessage(,, "F0500401",, "OBSERVA��O", "� obrigat�rio informar uma observa��o para a solicita��o.","Informe uma observa��o",,)	
			lSolicVal := .F.
		ElseIf aMotivo[1] .And. Empty(aMotivo[2])
			oModAtu:SetErrorMessage(,, "F0500401",, "OBSERVA��O", "� obrigat�rio informar uma observa��o para a solicita��o.","Informe uma observa��o",,)
			lSolicVal := .F.
		EndIf
	EndIf	
	
Return lSolicVal

/*{Protheus.doc} PrepGrv
Prepara��o para a grava��o dos dados da RH3 e RH4
@type Static function
@author Cris
@since 04/11/2016
@param oModel, objeto, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${l�gico}, ${.T. gravado com sucesso .F. n�o gravado}
*/
Static Function PrepGrv(oModAtu)
	
	Local aArea     := GetArea()
	Local aCabRH3   := {}
	Local aCampos   := {}
	Local aDados    := {}
	Local cEmailRe  := ''
	Local cNumSol   := ''
	Local cObsLog   := "Solicita��o de Movimenta��o de Pessoal Aberta"
	Local aAreaSRA  := {} // ticket 1906392 - Rogerio Carvalho - 21/12/2017
	Local cEmailSol := '' // ticket 1906392 - Rogerio Carvalho - 21/12/2017
	Local aMatInc   := {} // ticket 1906392 - Rogerio Carvalho - 21/12/2017

	//Carrega informa��es do usu�rio logado
	aMatInc	:= U_GetInfMat(.F.)		// ticket 1906392 - Rogerio Carvalho - 21/12/2017
	
	//Preparando o cabe�alho da solicita��o
	PrepDds(@aCabRH3,@cEmailRe)
	
	If Len(aCabRH3) > 0
		//Montando os itens da solicita��o
		FWMsgRun(,{|| MntInf(@aCampos,@aDados)},"Processando...","Preparando dados para grava��o." )
	EndIf
	
	If len(aCabRH3) > 0 .AND. len(aCampos) > 0 .AND. len(aCampos) == len(aDados)
		
		AADD(aCampos,"TMP_OBSINC")
		AADD(aDados,aMotivo[2])
		
		FWMsgRun(,{|| cNumSol :=  U_F0500106( 3, aCabRH3 , aCampos, aDados, SRA->RA_FILIAL )},"Processando...","Gravando a solicita��o." )
		
		//Verifica se realmente foi gravado a solicita��o
		dbSelectarea("RH3")
		RH3->(dbSetOrder(1))
		if RH3->(dbSeek(SRA->RA_FILIAL+cNumSol+SRA->RA_MAT))
			// ticket 1906392 - Rogerio Carvalho - 21/12/2017 : pega e-mail do solicitante cEmailSol
			aAreaSRA := GetArea()
			dbSelectarea("SRA")
			SRA->(dbSetOrder(1))
		    if SRA->(dbSeek(aMatInc[01]+aMatInc[02]))
				cEmailSol:=SRA->RA_EMAIL
			Endif
			Restarea(aAreaSRA)
			// Fim - ticket 1906392 - Rogerio Carvalho
			
			//MntEmail(RH3->RH3_CODIGO,RH3->RH3_MAT,SRA->RA_NOME,cEmailRe)
			cSubGrp := POSICIONE("PAB",1, XFILIAL("PAB") + RH3->RH3_XCODAL, "PAB_GRPSOL")

			// ticket 1906392 - Rogerio Carvalho - 21/12/2017 : pega e-mail do solicitante cEmailSol
			//U_F0800901("1",SRA->RA_EMAIL,RH3->RH3_FILIAL,RH3->RH3_CODIGO,SRA->RA_NOME,"006",cSubGrp,Strzero(RH3->RH3_NVLAPR,TAMSX3("RH3_XPRXNV")[1]),"")			
			U_F0800901("1",cEmailSol,RH3->RH3_FILIAL,RH3->RH3_CODIGO,SRA->RA_NOME,"006",cSubGrp,Strzero(RH3->RH3_NVLAPR,TAMSX3("RH3_XPRXNV")[1]),"")
			// Fim - ticket 1906392 - Rogerio Carvalho
						
			Aviso("Solicita��o","N�mero da solicita��o:"+RH3->RH3_CODIGO ,{'OK'},1)
			
		EndIf
	EndIf
	
	//Atualiza o funcion�rio para sinalizar que existe solicita��o em aberto
	if !Empty(cNumSol)
		SRA->(dbSetOrder(1))
		if SRA->(dbSeek(RH3->RH3_FILIAL+RH3->RH3_MAT))
			
			if SRA->(Reclock("SRA",.F.))
				SRA->RA_XSTMVTO	:= '1'
				SRA->(MsUnlock())
			Else				
				Help("",1, "Help", "Status Funcion�rio(PrepGrv_01)", "N�o foi poss�vel sinalizar no cadastro de funcion�rio que o  mesmo possui solicita��o em aberto!" , 3, 0)				
			EndIf
			
		EndIf
		
		//Grava o log de inclus�o da solicita��o 
		U_F0800201("1",RH3->RH3_FILIAL,cNumSol,aCabRH3[17][2],aCabRH3[5][2],aCabRH3[6][2],aCabRH3[12][2],aCabRH3[13][2],cObsLog,cEmailRe,Strzero(RH3->RH3_NVLAPR,TAMSX3("RH3_XPRXNV")[1]))
		
		U_F0500201(RH3->RH3_FILIAL,cNumSol,'001')
		If RH3->RH3_STATUS == "4"
			U_F0500201(RH3->RH3_FILIAL,cNumSol,'005')		
		Else
			U_F0500201(RH3->RH3_FILIAL,cNumSol,'002')
		EndIf
				
	EndIf
	
	lESalPrp	:= .F.
	lECarPrp	:= .F.           
	lEHorPrp	:= .F.
	lETurPrp	:= .F.
	lETrfPrp	:= .F.
	lValPosto	:= .T. //.T. Indica que o posto � v�lido, portanto possui vaga dispon�vel
	cSubGrp		:= ''  //Codigo da vis�o que ser� gravada
	
	//Desbloqueio o Modelo da Altera��o Salarial
	MtBCMod(oModAtu,{"SALDETAIL"},{||.T.})
	
	RestArea(aArea)
	
Return iif(!Empty(cNumSol),.T.,.F.)

/*{Protheus.doc} PrepDds
Monta o cabe�alho da RH3
@type Static function
@author Cris
@since 01/11/2016
@version 1.0
@param aCpoRH3, array, (array para popular com os dados da RH3)
@param cEmailRe, array, (e-mail do primeiro aprovador)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function PrepDds(aCpoRH3,cEmailRe)
	
	Local aAreaAtu  := SRA->(GetARea())
	Local cFilMat   := SRA->RA_FILIAL
	Local cMatric   := SRA->RA_MAT
	Local cFilSoli  := ""
	Local cMatSoli  := ""
	Local cNotif    := ""
	Local cStatus   := ""
	Local aRetSup   := {}
	Local aMatInc   := {}
	Local cFilPost := ""
	Local cCodPost := ""
	Local cQuery   := ""
	Local cAlias1  := GetNextAlias()
	Local cVisPAB  := ""
	Local cCodAlc  := ""
	
	//Carrego informa��es do usu�rio logado
	aMatInc  := U_GetInfMat()
	cFilSoli := aMatInc[01]
	cMatSoli := aMatInc[02]
			
	cQuery := "SELECT PAB_CODIGO, PAB_DTVLD "
	cQuery += "FROM	" + RetSqlName("PAB") + " "
	cQuery += "WHERE PAB_TPSOLI = '006' AND PAB_GRPSOL = '" + cSubGrp + "' AND PAB_DTVLD >= '" + dtos(date()) + "' AND "
	cQuery += "D_E_L_E_T_ = ' ' "
	cQuery += "ORDER BY PAB_DTVLD"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias1)
	If (cAlias1)->(!EOF())
		cCodAlc := (cAlias1)->(PAB_CODIGO)
	EndIf
	(cAlias1)->(DbCloseArea())
	
	cVisPAB := POSICIONE("PAB",1,xFilial("PAB")+cCodAlc,"PAB_VISAO")
	
	cAlias1 := GetNextAlias()
	
	cQuery := "SELECT RD4_CHAVE,RD4_FILIDE,RD4_CODIDE "
	cQuery += "FROM " + RetSqlName("RCX") + " RCX "
	cQuery += "INNER JOIN " + RetSqlName("RD4") + " RD4 ON(RD4.RD4_FILIDE = RCX.RCX_FILIAL AND "
	cQuery += "RD4.RD4_CODIDE = RCX.RCX_POSTO AND RD4.D_E_L_E_T_ = ' ') "
	cQuery += "WHERE RCX.RCX_FILFUN = '" + cFilSoli  + "' AND "
	cQuery += "RCX.RCX_MATFUN = '" + cMatSoli + "' AND "
	cQuery += "RD4.RD4_CODIGO = '" + cVisPAB + "' AND "
	cQuery += "RCX.D_E_L_E_T_ = ' '"
		
	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias1,.T.,.T.)
	
	If !(cAlias1)->(EOF())
		cFilPost := (cAlias1)->RD4_FILIDE
		cCodPost := (cAlias1)->RD4_CODIDE
	EndIf
	(cAlias1)->(DbCloseArea())

	aRetSup := U_F0800501("1",,,"006" ,cSubGrp,cFilSoli,cMatSoli,cFilMat,cMatric,,,,.F.)
	
	If aRetSup[1][1] //Encontrou aprovador
	
		cNotif := Posicione("PAC",1,xFilial("PAC")+aRetSup[1][6]+aRetSup[1][4],"PAC_APRNOT")
		
		If (aRetSup[1][5] == "FM" .And. cNotif == "2") .Or. (aRetSup[1][5] == "FM" .And. ("aprova direto" $ aRetSup[1][8] .OR. "Terminou a estrutura da vis�o!" $ aRetSup[1][8] ))
			cStatus := "4"
		Else
			cStatus := "1"
		EndIf
			
		aAdd( aCpoRH3 , {"RH3_MAT"		, cMatric})
		aAdd( aCpoRH3 , {"RH3_TIPO"		, " " })
		aAdd( aCpoRH3 , {"RH3_ORIGEM"	, "U_F0500401" })
		aAdd( aCpoRH3 , {"RH3_DTSOLI"	, dDataBase })
		aAdd( aCpoRH3 , {"RH3_FILINI"	, cFilSoli })
		aAdd( aCpoRH3 , {"RH3_MATINI"	, cMatSoli })
		aAdd( aCpoRH3 , {"RH3_EMPAPR"	, cEmpAnt })
		aAdd( aCpoRH3 , {"RH3_EMPINI"	, cEmpAnt })
		aAdd( aCpoRH3 , {"RH3_EMP"		, cEmpAnt })
		aAdd( aCpoRH3 , {"RH3_STATUS"	, cStatus })
		aAdd( aCpoRH3 , {"RH3_NVLAPR"	, VAL(aRetSup[1][4]) })
		aAdd( aCpoRH3 , {"RH3_FILAPR"	, aRetSup[1][2] })
		aAdd( aCpoRH3 , {"RH3_MATAPR"	, aRetSup[1][3] })
		aAdd( aCpoRH3 , {"RH3_KEYINI"	, "002" })
		aAdd( aCpoRH3 , {"RH3_FLUIG"	, 0 })
		aAdd( aCpoRH3 , {"RH3_XTPCTM"	, "006" })
		aAdd( aCpoRH3 , {"RH3_XCODAL"	, aRetSup[1][6] })
		aAdd( aCpoRH3 , {"RH3_XPRXNV"	, aRetSup[1][5] })
		If !Empty(aRetSup[1][9]) .AND. !Empty(aRetSup[1][10])
			AAdd( aCpoRH3 , {"RH3_XSUBST"	, "S" })
			AAdd( aCpoRH3 , {"RH3_XFILSU"	, aRetSup[1][9] })
			AAdd( aCpoRH3 , {"RH3_XMATSU"	, aRetSup[1][10] })
		EndIf
		AAdd( aCpoRH3 , {"RH3_XFILPO"	, cFilPost })
		AAdd( aCpoRH3 , {"RH3_XCODPO"	, cCodPost })
			
		cEmailRe	:= aRetSup[1][7]
			
		//Retorna para  o ponteiro inicial
		SRA->(dbSetOrder(1))
		SRA->(dbSeek(cFilMat+cMatric))
		
	Else
	
		Help("",1, "Help", "PrepDds", aRetSup[1][8] , 3, 0)			

	EndIf	
	
	RestArea(aAreaAtu)
	
Return

/*{Protheus.doc} SelecU04
(Seleciona a vis�o conforme aba(s) alterada(s)
@type Static function
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function SelecU04(cEscalm,cSalVali)
	
	Local aArea   := GetArea()
	Local cOpAlt  := If(lESalPrp,'X',' ')+If(lECarPrp,'X',' ')+If(lETurPrp .or. lEHorPrp,If(lEHorPrp,'XX',' X'),'  ')+If(lETrfPrp,'X',' ')
	Local cTabRCC := GetNextAlias()
	Local cQryRCC := ''
	Local lRet    := .T.
	
	cQryRCC	:= "SELECT SUBSTRING(RCC_CONTEU,6,3) SUBGRP, SUBSTRING(RCC_CONTEU,109,1) ESCALON, SUBSTRING(RCC_CONTEU,110,3) SBGPESC " + CRLF
	cQryRCC	+= "FROM "+RetSqlName("RCC")+" " + CRLF
	cQryRCC	+= "WHERE RCC_FILIAL = '"+FwxFilial("RCC")+"' " + CRLF
	cQryRCC	+= " AND RCC_CODIGO = 'U004' " + CRLF
	cQryRCC	+= " AND RCC_CONTEU LIKE '"+cOpAlt+'0%'+"' " + CRLF
	cQryRCC	+= " AND D_E_L_E_T_ = ' ' " + CRLF
	
	cQryRCC := ChangeQuery(cQryRCC)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryRCC),cTabRCC,.T.,.T.)
	
	If !(cTabRCC)->(Eof())
		If cEscalm == "1" //Sim
			If SUBSTR(cOpAlt,1,1) == "X" //Contempla Altera��o Salarial
				If (cTabRCC)->ESCALON == "S" .AND. !Empty((cTabRCC)->SBGPESC)
					cSubGrp	:= (cTabRCC)->SBGPESC
				Else
					cSalVali := "Necess�rio realizar parametriza��o na tabela U004 para m�rito."
					lRet := .F.		
				EndIf
			Else
				cSalVali := "M�rito apenas para solicita��es que contemplam altera��o salarial."
				lRet := .F.
			EndIf		
		Else
			cSubGrp	:= (cTabRCC)->SUBGRP
		EndIf
	EndIf
	
	(cTabRCC)->(dbCloseArea())
	
	RestArea(aArea)
	
Return lRet

/*{Protheus.doc} ${MntInf}
Monta as informa��es
@type function
@author Cris
@since 31/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function MntInf(aCampos,aDados)

	Local oModAtu := FWModelActive()
	
	If lETrfPrp .OR. lETurPrp .OR. lEHorPrp .OR. lECarPrp .OR. lESalPrp
	
		aAdd(aCampos,"TMP_FILIAL")
		aAdd(aCampos,"TMP_D_FILI")
		
		aAdd(aDados,oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_FILIAL"))
		aAdd(aDados,oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_D_FILI"))
	
	EndIf
	
	//Se existe transfer�ncia acumula valores
	if lETrfPrp
		
		CarregTf(@aCampos,@aDados)
		
	EndIf
	
	//Se existe troca de turno acumula valores
	if lETurPrp
		
		CarregTr(@aCampos,@aDados)
		
	EndIf
	
	//Se existe altera��o de carga hor�ria
	if lEHorPrp
		CarregHr(@aCampos,@aDados)
	EndIf
	
	//Se existe altera��o de cargo
	if lECarPrp
		
		CarregCr(@aCampos,@aDados)
		
	EndIf
	
	//Se existe altera��o salarial
	if lESalPrp
		     
		CarregSl(@aCampos,@aDados)
		
	EndIf	

		
Return

/*{Protheus.doc} CarregTf
Carrega a transfer�ncia
@type Static function
@author Cris
@since 31/10/2016
@param @aCampos, ${param_type}, (Descri��o do par�metro)
@param @aDados, ${param_type}, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function CarregTf(aCampos,aDados)
	
	Local oModAtu :=	FWModelActive()
	Local cFilTrf := oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")
	Local cCCTrf  := oModAtu:GetModel("TRFDETAIL"):GEtValue("CCUSTOPROP")
	Local cDepTrf := oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")
	Local cPosto  := ''
	Local cClVl   := ''
	Local cItem   := ''
	
	aAdd(aCampos,"TMP_TIPO")
	aAdd(aCampos,"TMP_CCATU")
	aAdd(aCampos,"TMP_D_CCAT")
	aAdd(aCampos,"TMP_DEPTOA")
	aAdd(aCampos,"TMP_D_DEPT")
	aAdd(aCampos,"TMP_DFUNCAO")
		
	aAdd(aDados,	"5")
	aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_CCATU"))
	aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_D_CCAT"))
	aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_DEPTOA"))
	aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_D_DEPT"))
	aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_DFUNCAO"))
	
	//Quando  SIGAORG for por posto
	if cTipOrgA ==  '1'
		
		aAdd(aCampos,"TMP_POSTO")
		aAdd(aDados, oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_POSTO"))
		cPosto	:= 	oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP")
		
	EndIf
	
	//Quando utiliza classe  valor
	if cClasVlA == '1'
		
		aAdd(aCampos,"TMP_CLVL")
		aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_CLVL"))
		aAdd(aCampos,"TMP_ITEM")
		aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_ITEM"))
		cClVl	:= 	oModAtu:GetModel("TRFDETAIL"):GEtValue("CLVLPROP")
		cItem	:= 	oModAtu:GetModel("TRFDETAIL"):GEtValue("ITEMPROP")
		
	EndIf
	
	//Filial de Destino
	if !Empty(cFilTrf)
		
		aAdd(aCampos,	"RA_FILIAL")//FILIPROP
		aAdd(aCampos,	"TMP_N_F_D")
		aAdd(aDados,	cFilTrf	)
		aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_N_F_D"))
		
	EndIf
	
	//Centro de Custo de Destino
	if !Empty(cCCTrf)
		
		aAdd(aCampos,	"RA_CC")//CCUSTOPROP
		aAdd(aCampos,	"TMP_D_CC_D")
		aAdd(aDados,	cCCTrf	)
		aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_D_CC_D"))
		
	EndIf
	
	//Departamento de Destino
	if !Empty(cDepTrf)
		
		aAdd(aCampos,	"RA_DEPTO")//DEPTOPROP
		aAdd(aCampos,	"TMP_D_DEPD")
		aAdd(aDados,	cDepTrf	)
		aAdd(aDados,	oModAtu:GetModel("TRFDETAIL"):GEtValue("TMP_D_DEPD"))
		
	EndIf

	//Posto
	if !Empty(cPosto)
		
		aAdd(aCampos,"RA_POSTO")
		aAdd(aDados, cPosto)
		
	EndIf
	
	if !Empty(cClVl)
		
		aAdd(aCampos,"RA_CLVL")
		aAdd(aDados, cClVl)
		
	EndIf
	
	if !Empty(cItem)
		
		aAdd(aCampos,"RA_ITEM")
		aAdd(aDados, cItem)
		
	EndIf
	
Return

/*{Protheus.doc} CarregTr
Carrega os dados a serem gravados na RH4 referente ao turno
@type function
@author Cris
@since 31/10/2016
@param @aCampos, ${param_type}, (Descri��o do par�metro)
@param @aDados, ${param_type}, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function CarregTr(aCampos,aDados)
	
	Local oModAtu := FWModelActive()
	
	aAdd(aCampos,"TMP_TIPO")
	aAdd(aCampos,"TMP_TURNAT")
	aAdd(aCampos,"TMP_D_TURN")
	aAdd(aCampos,"TMP_S_TURN")
	aAdd(aCampos,"TMP_REGRA")
	aAdd(aCampos,"RA_TNOTRAB")//TURNOPROP
	aAdd(aCampos,"TMP_DESCTU")
	aAdd(aCampos,"RA_SEQTURN")//STURPROP
	aAdd(aCampos,"RA_REGRA")	//REGRAPROP
	
	aAdd(aDados,	"4")
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_TURNAT"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_D_TURN"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_S_TURN"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_REGRA"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TURNOPROP"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("TMP_DESCTU"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("STURPROP"))
	aAdd(aDados,	oModAtu:GetModel("TURDETAIL"):GEtValue("REGRAPROP"))
	
Return

/*{Protheus.doc} CarregHr
Carrega os dados  a serem gravados na RH4 para solicitar a altera��o referente a Carga Hor�ria
@type function
@author Cris
@since 31/10/2016
@param @aCampos, ${param_type}, (Descri��o do par�metro)
@param @aDados, ${param_type}, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function CarregHr(aCampos,aDados)
	
	Local oModAtu := FWModelActive()
	
	aAdd(aCampos,"TMP_TIPO")
	aAdd(aCampos,"TMP_H_M_AT")
	aAdd(aCampos,"TMP_H_S_AT")
	aAdd(aCampos,"TMP_H_D_AT")
	aAdd(aCampos,"RA_HRSMES")//HMESPROP
	aAdd(aCampos,"RA_HRSEMAN")//HSEMPROP
	aAdd(aCampos,"RA_HRSDIA")//HDIAPROP
	
	aAdd(aDados,	"3")
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("TMP_H_M_AT"),GetSx3Cache("RA_HRSMES","X3_PICTURE")))
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("TMP_H_S_AT"),GetSx3Cache("RA_HRSEMAN","X3_PICTURE")))
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("TMP_H_D_AT"),GetSx3Cache("RA_HRSDIA","X3_PICTURE")))
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP"),GetSx3Cache("RA_HRSMES","X3_PICTURE")))
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("HSEMPROP"),GetSx3Cache("RA_HRSEMAN","X3_PICTURE")))
	aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("HDIAPROP"),GetSx3Cache("RA_HRSDIA","X3_PICTURE")))

    // Jamer Pedroso - 17/05/2017   
   If !( SRA->RA_ADCINS$"1| ") // No caso de insalubridade � atualizado o campos de horas insalubridade.
	   aAdd(aCampos,"RA_INSMAX")//HDIAPROP
	   aAdd(aDados,	Transform(oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP"),GetSx3Cache("RA_INSMAX","X3_PICTURE")))
   EndIf
	
Return

/*{Protheus.doc} CarregCr
Carrega os dados a serem gravados na RH4 que foram solicitados para serem altera��o referente ao Cargo
@type function
@author Cris
@since 31/10/2016
@param @aCampos, ${param_type}, (Descri��o do par�metro)
@param @aDados, ${param_type}, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function CarregCr(aCampos,aDados)
	
	Local oModAtu := FWModelActive()
	
	aAdd(aCampos,"TMP_TIPO")
	aAdd(aCampos,"TMP_FUNCAO")//TMP_FUNCAO
	aAdd(aCampos,"TMP_D_FUNC")
	aAdd(aCampos,"RA_CODFUNC")//RA_CARGO-CARGOPROP
	aAdd(aCampos,"TMP_D_F_PP")
	aAdd(aCampos,"RA_TIPOALT")//MALTCARSAL
	aAdd(aCampos,"TMP_D_MOT")//TMP_D_MOTC
	
	aAdd(aDados,	"2")
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_CARGO"))
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_D_FUNC"))
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("CARGOPROP"))
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_D_F_PP"))
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("MALTCARSAL"))
	aAdd(aDados,	oModAtu:GetModel("CARDETAIL"):GEtValue("TMP_D_MOTC"))
	
Return

/*{Protheus.doc} CarregSl
Carrega os dados a serem gravados na RH4 referente a altera��o Salarial.
@type Static function
@author Cris
@since 31/10/2016
@param aCampos, array, (Descri��o do par�metro)
@param aDados, array, (Descri��o do par�metro)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function CarregSl(aCampos,aDados)
	
	Local oModAtu := FWModelActive()
	
	aAdd(aCampos,"TMP_TIPO")
	aAdd(aCampos,"TMP_FUNCAO")
	aAdd(aCampos,"TMP_D_FUNC")
	aAdd(aCampos,"TMP_SALATU")
	aAdd(aCampos,"TMP_TABELA")
	aAdd(aCampos,"TMP_NIVELT")
	aAdd(aCampos,"TMP_FAIXAT")
	aAdd(aCampos,"RA_SALARIO")//SALARIOPROP
	aAdd(aCampos,"TMP_VLSALA")
	aAdd(aCampos,"TMP_PERCSA")
	aAdd(aCampos,"RA_TIPOALT")//MOTALTSAL
	aAdd(aCampos,"TMP_D_MOT")
	
	aAdd(aDados,	"1")
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_CARGO"))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_D_FUNC"))
	aAdd(aDados,	Alltrim(Transform(oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_SALATU"),GetSx3Cache("RA_SALARIO","X3_PICTURE"))))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_TABELA"))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_NIVELT"))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_FAIXAT"))
	aAdd(aDados,	Alltrim(Transform(oModAtu:GetModel("SALDETAIL"):GEtValue("SALARIOPROP"),GetSx3Cache("RA_SALARIO","X3_PICTURE"))))
	aAdd(aDados,	Alltrim(Transform(oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_VLSALA"),GetSx3Cache("RA_SALARIO","X3_PICTURE"))))
	aAdd(aDados,	Alltrim(Transform(oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_PERCSA"),'@E 999.99')))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("MOTALTSAL"))
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_D_MOT"))
	
	// Grava a informa��o de M�rito
	aAdd(aCampos,"TMP_ESCL")
	aAdd(aDados,	oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_ESCL"))
Return

/*{Protheus.doc} MntEmail
Monta os dados do e-mail
@type function
@author Cris
@since 09/11/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function MntEmail(cCodRH3,cMatAtu,cNomeFun,cEmailRe)
	
	Local cAssunto  := ''
	Local cBody     := ''
	Local lEnvEmail := .T.
	
	cAssunto := "Solicita��o de Movimenta��es de Pessoal:"
	
	cBody := '<html><body><pre>'+CRLF
	cBody += '<b>Prezado,</b>'+CRLF
	cBody += "Incluido uma nova solicita��o que esta aguardando sua aprova��o/reprova��o, a acesse atrav�s do portal de RH."+CRLF
	cBody += "N�mero da Solicita��o:"+cCodRH3+CRLF
	cBody += '</pre></body></html>'
	
	//FWMsgRun(,{|| U_F0200304(cAssunto, cBody, cEmailRe)},"Aguarde...","Estabelecendo conex�o com o servi�o de e-mail." )
	FWMsgRun(,{|| lEnvEmail:= EnvEmail("",cAssunto,cBody,cEmailRe,"")},"Aguarde...","Estabelecendo conex�o com o servi�o de e-mail." )
	
	if lEnvEmail
		
		Aviso("SUCESSO - Email","E-mail enviado com sucesso!" ,{'OK'},1)
		
	Else
		
		Aviso("INSUCESSO - Email","E-mail N�O enviado. Comunique aos envolvidos!" ,{'OK'},1)
		
	EndIf
	
Return

/*{Protheus.doc} ${EnvEmail}
(Envia e-mail)
@type function
@author Cris
@since 09/11/2016
@version 1.0
@param cArquivo, character, (nome do arquivo a ser anexado)
@param cSubject, character, (Titulo do e-mail)
@param cBody, character, (Corpo do e-mail)
@param cTo, character, (endere�o de Destino do e-mail)
@param cCC, character, (endere�o copia de destino)
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${return}, ${n�o h�}
*/
Static Function EnvEmail(cArquivo,cSubject,cBody,cTo,cCC)
	
	Local cServer    := AllTrim(GetMv("MV_RELSERV"))
	Local cFrom      := AllTrim(GetMv("MV_RELACNT"))
	Local lAutentica := GetMv("MV_RELAUTH")
	Local cUserAut   := Alltrim(GetMv("MV_RELAUSR"))
	Local cPassAut   := Alltrim(GetMv("MV_RELAPSW"))
	
	Default cArquivo := ""
	Default cSubject := ""
	Default cBody    := ""
	Default cTo      := ""
	Default cCC      := ""
	
	If Empty(cServer)
		conout("F0500401: Nome do Servidor de Envio de E-mail nao definido no 'MV_RELSERV'")
		Return .F.
	EndIF
	
	IF Empty(cFrom)
		conout("F0500401: Conta para acesso ao Servidor de E-mail nao definida no 'MV_RELACNT'")
		Return .F.
	EndIf
	
	cTo := AvLeGrupoEMail(cTo)
	cCC := AvLeGrupoEMail(cCC)
	
	lOK	:= MailSmtpOn( cServer, cFrom, cPassAut, 60 )
	
	If !lOK
		
		conout("F0500401: Falha na Conex�o com Servidor de E-Mail")
		//Aviso('Email n�o enviado',"Falha na Conex�o com Servidor de E-Mail. ",{'OK'},3)
		
	Else
		
		If lAutentica
			If !MailAuth(cUserAut,cPassAut)
				//Aviso('Email n�o enviado',"Falha na Autentica��o do Usu�rio. ",{'OK'},3)
				conout("F0500401: Falha na Autenticacao do Usuario")
				lOk	:=	MailSmtpOff()
			EndIf
		EndIf
		
		If !Empty(cCC)
			lOK:=MailSend( cFrom, { cTo }, { cCC }, { }, cSubject, cBody, { cArquivo },.F. )
		Else
			lOK:=MailSend( cFrom, { cTo }, { }, { }, cSubject, cBody, { cArquivo },.F. )
		EndIF
		If !lOK
			if !IsBlind()
				///Aviso('Email n�o enviado',"Falha no Envio do E-Mail: "+ALLTRIM(cTo),{'OK'},3)
			Else
				conout("F0500401: Falha no Envio do E-Mail: "+ALLTRIM(cTo))
			EndIF
		Else
			if  !IsBlind()
				//Aviso("Envio de Email",'E-mail enviado com sucesso.', {'OK'},3)
			EndIf
		EndIF
	ENDIF
	
	MailSmtpOff()
	
RETURN lOK

/*{Protheus.doc} VldPermis
Valida se o usu�rio tem permiss�o para realizar movimenta��o
@author		Cris
@since		09/11/2016
@version	P12.1.7
@Project	MAN0000007423039_EF_004
@Param		cFilFun, caracter, Filial do funcion�rio
@Param		cMatFun, caracter, Matricula do funcion�rio
@return		lRet, permite ou n�o permite realizar movimenta��o
*/
Static Function VldPermis()
	
	Local lRet := .F.
	Local aEquipe := {}
	Local nX := 0
	
	Local cFilFun := SRA->RA_FILIAL
	Local cMatFun := SRA->RA_MAT
	
	aEquipe := U_F0500198()
	
	nPos := aScan(aEquipe,{|x| x[3]+x[4]==cFilFun+cMatFun })
	If nPos > 0
		lRet := .T.
	EndIf
	
	If !lRet
		Help("",1, "Help", "Aten��o", "Usu�rio n�o tem permiss�o para realizar movimenta��o para esse funcion�rio" , 3, 0)
	EndIf
	
Return lRet

/*{Protheus.doc} MdSalHr
Valor do salario hora
@author		Cris
@since		09/11/2016
@version	P12.1.7
@Project	MAN0000007423039_EF_004
@return		nSal, valor do salario hora
*/
Static Function MdSalHr()
	
	Local nSal := 0
	
	//nSal := Round((SRA->RA_SALARIO / SRA->RA_HRSMES),2)
	nSal := SRA->RA_SALARIO / SRA->RA_HRSMES
//	nSal := SRA->RA_SALARIO / SRA->RA_HRSMES
	
Return nSal

/*
{Protheus.doc} SetStatic()
Pr� Valida��o do Model
@Author     Nairan Alves
@Since      04/01/2018
@Version    P12.1.07
*/
Static Function SetStatic()
	lESalPrp		:= .F. //.T. Indica que  existe altera��o salarial
	lECarPrp		:= .F. //.T. Indica que existe altera��o de Cargo
	lEHorPrp		:= .F. //.T. Indica que existe altera��o de Carga Hor�ria
	lETurPrp		:= .F. //.T. Indica que existe altera��o de Turno
	lETrfPrp		:= .F. //.T. Indica que existe transfer�ncia
	lValPosto		:= .T. //.T. Indica que o posto � v�lido, portanto possui vaga dispon�vel
	cSubGrp		    := ''  //Codigo do subgrupo
	cDepSolc		:= ''
	lBOracle		:= Trim(TcGetDb()) = 'ORACLE'
	cTipOrgA		:= GetMV('MV_ORGCFG')//1- por posto, 2 - por departamento 0-n�o tem integra��o
	cClasVlA		:= GetMV('MV_ITMCLVL')//1 � Utiliza Item Cont�bil e Classe de Valores.,2 � N�o Utiliza Item Cont�bil e Classe de Valores.
	aMotivo			:= {}
Return .T.

/*
{Protheus.doc} F0500425()
Valida��o para cancelamento da solicita��o
@Author     Bruno de Oliveira
@Since      15/12/2017
@Version    P12.1.07
@Project    MAN0000007423048_EF_025
*/
User Function F0500425(cAliasSra)

	Local aAreaRH3  := RH3->(GetArea())
	Local lSolicita := .F.
	Local aUser     := {}
	Local cFSolic   := ""
	Local cMSolic   := ""
	Local cStatus   := ""
	Local cAlcada   := ""
	Local cSubGrp   := ""
	Local cCodSRA   := (cAliasSra)->RA_FILIAL+(cAliasSra)->RA_MAT
	
	RH3->(DbSetOrder(2))
	If AllTrim((cAliasSra)->RA_XSTMVTO) == "1"
		If RH3->(DbSeek((cAliasSra)->RA_FILIAL + (cAliasSra)->RA_MAT))
			While RH3->(RH3_FILIAL + RH3_MAT) ==  (cAliasSra)->RA_FILIAL + (cAliasSra)->RA_MAT 
				If AllTrim(RH3->RH3_XTPCTM) == "006" .And. RH3->RH3_STATUS $ "1,4"
					lSolicita := .T.
					cFilSol := RH3->RH3_FILIAL
					cCodSol := RH3->RH3_CODIGO
					cFSolic := RH3->RH3_FILINI
					cMSolic := RH3->RH3_MATINI
					cStatus := RH3->RH3_STATUS
					Exit
				EndIf
				RH3->(DbSkip())
			EndDo
		EndIf
	EndIf
	
	If lSolicita
		aUser	:= U_GetInfMat()
	
		If !Empty(aUser[1]) .AND. !Empty(aUser[2])
			If aUser[1]+aUser[2] == cFSolic+cMSolic
				U_CanclSlc(cFilSol,cCodSol,cCodSRA,cFSolic,cMSolic,"006")			
			Else
				MsgAlert("Usu�rio n�o tem permiss�o para cancelar a solicita��o")
			EndIf
		EndIf
	Else
		Help("",1, "Help", "Aten��o", "N�o existe solicita��o em aberto para este colaborador." , 3, 0)
	EndIf
	
	RestArea(aAreaRH3)

Return

// --------------------------------------------------------------
// Chamada para posicionamento do registro no fonte F0500413.prw 
// --------------------------------------------------------------
Function U_X0500401() 
	// Ticket No.3985154 - 418497 - Don Junior - Corre��o erro Alias does not exist
	U_F0500413( (TSRA)->RA_FILIAL,(TSRA)->RA_MAT,@oBrowse )
Return

/*{Protheus.doc} FSVLSALP
Retorna a valida��o das informa��es de valores referente ao sal�rio
@type Static function
@author Cris
@since 25/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lValSal}, ${.T. informa��es de salario v�lidas .F. informa��es n�o v�lidas}
*/
Static Function GFSVLSALP()
	
	Local oModAtu  := FWModelActive()
	Local nValSal  := oModAtu:GetModel("SALDETAIL"):GEtValue("SALARIOPROP")
	Local nSalHr   := 0
	Local nValReal := 0
	Local lValSal  := .T.
	
//    MDGatilho(2) // gus
	
	//Validar se o sal�rio proposto esta diferente do  atual
	if nValSal <> 0
		
		//Efetuar diversar valida��es de acordo com a EF
		if SRA->RA_SALARIO <> nValSal
			
			If SRA->RA_SALARIO > nValSal
				
				if oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") == 0
					
					Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_03)", "Para reduzir o sal�rio � necess�rio efetuar a solicita��o atrav�s da Carga Hor�ria!" , 3, 0)
					lValSal	:= .F.
				Else
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de Sal�rio(FSVLSALP_04)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf
				EndIf
			Else
				If oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") <> 0
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_05)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf 
				EndIf
			EndIf
			
		Else
			
			Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_01)", "Informe um sal�rio proposto diferente do atual!" , 3, 0)
			lValSal		:= .F.
			
		EndIf
		
		if lValSal						
			lESalPrp	:= .T. //Indica que existe altera��o salarial			
		Else			
			lESalPrp	:= .F. //Indica que nao existe altera��o salarial			
		EndIf
		
	Else
		
		lESalPrp	:= .F. //Indica que nao existe altera��o salarial
		
	EndIf
	
Return lValSal

/*{Protheus.doc} F00504VL
valida��o total no bot�o Confirmar
@type Static function
@author Cris
@since 28/10/2016
@version P12.1.7
@Project MAN0000007423039_EF_004
@return ${lSolicVal}, ${.T. solicita��o valida .F. solicita��o n�o valida}
*/
Static Function GF00504VL()
	
	Local oModAtu   := FWModelActive()
	Local lSolicVal := .T.
	Local lSalProp  := FSVLSALP()
	Local cSalVali  := " "
	Local lCarProp  := FSVLCARP()
	Local lTurProp  := FSVLTURP()
	Local lHorProp	:= FSVLHORP() // ticket n� 2669524 [AMS] - Paulo Dias - 11/05/2018

//	Local lTrfProp  := FSVLTRFP("POSTOD")
	Local cFilProp  := oModAtu:GetModel( 'TRFDETAIL' ):GetValue( 'FILIPROP' )
	Local _cMsgVld	:= Iif(!empty( cFilProp ),VLDPOSTOD(),"") //7780516 - Thais Paiva
	Local lTrfProp  := Empty(Alltrim(_cMsgVld)) //( !empty( cFilProp ) .AND. FSVLTRFP( 'POSTOD' ) ) 7780516 - Thais Paiva
	Local cTitulo   := "Motivo de inclus�o"
	Local cEscalm   := oModAtu:GetModel("SALDETAIL"):GetValue("TMP_ESCL")
	
// --------------------------------------------------------

//	Local oModAtu  := FWModelActive()
	Local nValSal  := oModAtu:GetModel("SALDETAIL"):GEtValue("SALARIOPROP")
	Local nSalHr   := 0
	Local nValReal := 0
	Local lValSal  := .T.
	
//    MDGatilho(2) // gus
	
	//Validar se o sal�rio proposto esta diferente do  atual
	if nValSal <> 0
		
		//Efetuar diversar valida��es de acordo com a EF
		if SRA->RA_SALARIO <> nValSal
			
			If SRA->RA_SALARIO > nValSal
				
				if oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") == 0
					
					Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_03)", "Para reduzir o sal�rio � necess�rio efetuar a solicita��o atrav�s da Carga Hor�ria!" , 3, 0)
					lValSal	:= .F.
				Else
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de Sal�rio(FSVLSALP_04)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf
				EndIf
			Else
				If oModAtu:GetModel("HORDETAIL"):GEtValue("HMESPROP") <> 0
				
					nValReal := Round((FwFldGet("HMESPROP")*FwFldGet("TMP_SALHR")),2)//-Ademar
					
					If nValSal < nValReal
						Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_05)", "Sal�rio n�o pode ser menor que " + Transform(nValReal, "@E 999,999.99" ) + " devido carga hor�rio informada!" , 3, 0)
						lValSal	:= .F.
					EndIf 
				EndIf
			EndIf
			
		Else
			
			Help("",1, "Help", "Valida��o de  Sal�rio(FSVLSALP_01)", "Informe um sal�rio proposto diferente do atual!" , 3, 0)
			lValSal		:= .F.
			
		EndIf
		
		if lValSal						
			lESalPrp	:= .T. //Indica que existe altera��o salarial			
		Else			
			lESalPrp	:= .F. //Indica que nao existe altera��o salarial			
		EndIf
		
	Else
		
		lESalPrp	:= .F. //Indica que nao existe altera��o salarial
		
	EndIf
	
    if lValSal

// --------------------------------------------------------

		aMotivo := {}
		
		//Se existe altera��o salarial, valida se foi informado o motivo
		if lESalPrp .AND. lSalProp
			
			if !(lSolicVal := MOTALTSL())
				
				cSalVali := "Inconsist�ncias na altera��o salarial: Informe o motivo da  altera��o.(Para altera��o exclusiva de carga horaria e Troca de Turno informar o motivo '013')"
				
			EndIf
			
		EndIf
		
		//Se existe altera��o de cargo, valida se foi informado o motivo.
		//poss�vel cen�rio: quando existir transfer�ncia
		if lSolicVal .AND. lECarPrp .AND. lCarProp
			
			if !(lSolicVal := MOTALTCG())
				
				cSalVali := cSalVali + " Inconsist�ncias na altera��o de cargo: Informe o motivo da altera��o.(Para altera��o exclusiva de carga horaria e Troca de Turno informar o motivo '013')"
				
			EndIf
			
		EndIf
		
		if lSolicVal .AND. !lETurPrp .AND. lEHorPrp
			
			cSalVali  := "Ao solicitar a altera��o de Carga Hor�ria � necess�rio alterar o turno de trabalho."
			lSolicVal := .F.
			
		EndIf
		//In�cio - 7780516 - Thais Paiva
		If lSolicVal .AND. !lTrfProp .AND. !Empty(Alltrim(_cMsgVld))
			cSalVali  := _cMsgVld
			lSolicVal := .F.
		EndIf
		
		
		//if lETrfPrp .AND. !lTrfProp
		if lSolicVal .AND. lETrfPrp .AND. !lTrfProp
		//Fim - 7780516 - Thais Paiva
			
			cSalVali  := "Verifique as informa��es para a transfer�ncia."
			lSolicVal := .F.
			
		EndIf
		
		//if !lETrfPrp .AND. lECarPrp 7780516 - Thais Paiva
		if lSolicVal .AND. !lETrfPrp .AND. lECarPrp
			
			cSalVali  := "Para alterar o Cargo � necess�rio tamb�m realizar uma transfer�ncia de posto."
			lSolicVal := .F.
			
		EndIf
		
		//Verifico se existe solicita��o de posto em aberto e  se existe se o n�mero de solicita�oes ultrapassa o numero disponivel de posto
		if lSolicVal .AND. lETrfPrp//(lECarPrp .OR. lETrfPrp)
			
			//ValPosto()//Verifica se existe disponibilidade do posto 7780516 - Thais Paiva
			cSalVali := ValPosto()
			if lValPosto
				
				//U_F0060101() requisito N005 Indicadores
				lSolicVal := .T.
				
			Else
				//In�cio - 7780516 - Thais Paiva
				If !Empty(Alltrim(cSalVali)) 
					lSolicVal := .F.
				Else
				//Fim - 7780516 - Thais Paiva
					If !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")) .OR. !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")) .OR. !Empty(oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP"))
						cSalVali  := "N�o existe posto dispon�vel para as informa��es de altera��o."
						lSolicVal := .F.
					EndIf
				EndIf //7780516 - Thais Paiva
			EndIf
			
		EndIf
		
		if lSolicVal
			
			if lESalPrp .And. !Empty(GetMv("FS_PSALSUP",,15)) .And. oModAtu:GetModel("SALDETAIL"):GEtValue("TMP_PERCSA") >= GetMv("FS_PSALSUP",,15)
				
				cSubGrp := GetMv("FS_VSALSUP") //C�digo do SubGrupo quando ultrapassar o limite definido de percentual para o aumento salarial
				
			Else
				
				lSolicVal := SelecU04(cEscalm,@cSalVali) //Seleciona o Codigo do SubGrupo
				
			EndIf
			
			If lSolicVal .AND. Empty(cSubGrp) //verificar
				
				cSalVali  := 'N�o localizado o c�digo do SubGrupo para este tipo de solicita��o. Verifique a tabela U004.'
				lSolicVal := .F.
				
			EndIf
			
		EndIf
		
		If !lSolicVal
			
			Help(,1, "Help", "Valida��o da solicita��o(F00504VL_01)", "Solicita��o n�o ser� gravada! "+cSalVali , 3 , 0)
			
		EndIf
		
		If lSolicVal
			aMotivo := U_Motivo(cTitulo)
			If !(aMotivo[1])
				oModAtu:SetErrorMessage(,, "F0500401",, "OBSERVA��O", "� obrigat�rio informar uma observa��o para a solicita��o.","Informe uma observa��o",,)	
				lSolicVal := .F.
			ElseIf aMotivo[1] .And. Empty(aMotivo[2])
				oModAtu:SetErrorMessage(,, "F0500401",, "OBSERVA��O", "� obrigat�rio informar uma observa��o para a solicita��o.","Informe uma observa��o",,)
				lSolicVal := .F.
			EndIf
		EndIf
	
	else
//	    oModAtu:GetModel("SALDETAIL"):setfocus()
	    oView:Refresh()
        oView:GetViewObj("SALDETAIL")[3]:getFWEditCtrl("SALARIOPROP"):oCtrl:SetFocus()
	    lSolicVal := .F.
	endif	
	
Return lSolicVal

//In�cio - 7780516 - Thais Paiva
Static Function VLDPOSTOD()
Local oModAtu  := FWModelActive()
Local cFilTrf  := oModAtu:GetModel("TRFDETAIL"):GEtValue("FILIPROP")
Local cCCTrf   := oModAtu:GetModel("TRFDETAIL"):GEtValue("CCUSTOPROP")
Local cDepTrf  := oModAtu:GetModel("TRFDETAIL"):GEtValue("DEPTOPROP")
Local cCargSRA := oModAtu:GetModel("CARDETAIL"):GetValue("TMP_CARGO")
Local cCargPrp := oModAtu:GetModel("CARDETAIL"):GetValue("CARGOPROP")
Local cPostTrf := ""
Local lValTrf  :=	.F.
Local cFilRCL  := IIf(Empty(FwxFilial("RCL")),FwxFilial("RCL"),iif(len(Alltrim(FwxFilial("RCL")))<=4,FwxFilial("RCL"),IIf(!Empty(cFilTrf),cFilTrf,SRA->RA_FILIAL)))
Local aAreaAtu := GetArea()
Local lLibPst  := SuperGetMv("FS_BLQSOL",,.F.)
Local _cMsgRet	:= ""

If cTipOrgA == '1'
	cPostTrf  :=  oModAtu:GetModel("TRFDETAIL"):GEtValue("POSTOPROP")
EndIf
	
If !Empty(cPostTrf)	
	If Empty(cDepTrf)				
		cDepTrf := oModAtu:GetModel("TRFDETAIL"):GetValue("TMP_DEPTOA")
	EndIf
	nTotal := U_F0500314(cDepTrf, cFilRCL, cPostTrf)
	dbSelectArea("RCL")
	RCL->(dbSetORder(1))//RCL_FILIAL, RCL_DEPTO, RCL_POSTO, R_E_C_N_O_, D_E_L_E_T_
	If !RCL->(dbSeek(cFilRCL + cDepTrf + cPostTrf))
		_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_1) - Informe um posto existente!"			
	ElseIf (RCL->RCL_NPOSTO - RCL->RCL_OPOSTO) == 0
		If !lLibPst
			_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_2) - Este posto esta totalmente ocupado!"			
		Else
			//Se o Cargo Do Posto proposto for diferente
			If Empty(cCargPrp)
				If RCL->RCL_CARGO != cCargSRA
					_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_3) - O cargo do posto � diferente do cargo do funcion�rio!"					
				EndIf
			Else
				If RCL->RCL_CARGO != cCargPrp
					_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_4) - O cargo do posto � diferente do cargo proposto!"						
				EndIf
			EndIf
		EndIf	
	ElseIf (RCL->RCL_NPOSTO <= (RCL->RCL_OPOSTO + nTotal)) 
		If !lLibPst
			_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_5) - Existe solicita��es vinculadas a esse posto, Favor verificar."
		EndIf
	Else
		//Se o Cargo Do Posto proposto for diferente
		If Empty(cCargPrp)
			If RCL->RCL_CARGO != cCargSRA
				_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_6) - O cargo do posto � diferente do cargo do funcion�rio!"
			EndIf
		Else
			If RCL->RCL_CARGO != cCargPrp
				_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_7) - O cargo do posto � diferente do cargo proposto!"
			EndIf
		EndIf
	EndIf
Else
	_cMsgRet := "Valida��o da Transfer�ncia(VLDPOSTOD_7) - Aten��o: � obrigat�rio preencher o campo POSTO!"  //ticket n� 9203072 -- cria valida��o para preenchimento obrigat�rio do campo POSTO
EndIf


Return _cMsgRet
//Fim - 7780516 - Thais Paiva
