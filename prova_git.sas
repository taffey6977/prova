/********************************************
Programma per creare le tabelle per l'upload 
su Arcipelago (dashboard)
Tabella Arcipelago 001
********************************************/

LIBNAME FAR_2016 '/sasprd/staging/staging_san1/S1_ORPSS/config/FAR_2016';
LIBNAME FAR_2017 '/sasprd/staging/staging_san1/S1_ORPSS/config/FAR_2017';
LIBNAME FAR_2018 '/sasprd/staging/staging_san1/S1_ORPSS/config/FAR_2018';
LIBNAME ARCIPE '/sasprd/staging/staging_san1/S1_ORPSS/config/Arcipelago';

%include '/sasprd/staging/staging_san1/S1_ORPSS/config/MACRO_ORPSS/far_anagrafica_con_errori.sas' ;
%include '/sasprd/staging/staging_san1/S1_ORPSS/config/MACRO_ORPSS/far_udo_atti.sas' ;

%let anno=2016;
%let fase=12; 

%SET_ANAGRAFICA_FAR(&anno,&fase);
%SET_UDO;

%macro comuni;
data c; set ARCIPE.comuni ; run; 

proc sort data=c; by cod_comune_esteso descending data_in_val; run;
data c; 
set c; 
by cod_comune_esteso; 
if first.cod_comune_esteso then conta1=1; else conta1+1; 
run; 

data c1; set c; where conta1=1; run; 

data c1; set c1;
cod_comune_str=put(cod_comune_esteso, 5.);
istres_in=cats('0', cod_comune_str);run;
run; 

data comuni_per_merge; set c1; keep istres_in cod_azienda; run; 

data comuni_per_merge; set comuni_per_merge; rename cod_azienda=ulss_a1_comuni; run; 
%mend; 



%MACRO ARCIPELAGO_1;
data ana_&anno.; set ana_&anno.; rename cod_ente=ulss_a1; run;

data ana_&anno.;
	set ana_&anno.;
	k=cats(ID_EPISODIO,ULSS_A1,CODICE_SOGGETTO_BIN);
RUN;

/*CALCOLO DIRETTAMENTE L'ETA' all'ultimo giorno del mese (&fase) e &anno */
data ana_&anno.;
	set ana_&anno.;
/*	eta=int((mdy(12,31,&anno.)-DATANASC)/365);*/

	IF ( &fase in (1,3,5,7,8,10,12) ) 		THEN eta=int((mdy(&fase,31,&anno)-DATANASC)/365.25);
	IF ( &fase in (4,6,9,11) ) 				THEN eta=int((mdy(&fase,30,&anno)-DATANASC)/365.25);
	IF ( (mod(&anno,4)=0) and &fase = 2)	THEN eta=int((mdy(&fase,29,&anno)-DATANASC)/365.25);
	IF ( (mod(&anno,4) ne 0) and &fase = 2) THEN eta=int((mdy(&fase,28,&anno)-DATANASC)/365.25);

run;

data ana_&anno.;
	set ana_&anno.;

	if eta=. then
		cleta=.;

	if 0<=eta<=64 then
		cleta=1;

	if 65<=eta<=74 then
		cleta=2;

	if 75<=eta<=84 then
		cleta=3;

	if eta>=85 then
		cleta=4;
	format cleta fascia_eta.;
RUN;


data arcipelago1;
	set ana_&anno.;
	keep 
		codice_soggetto_bin
		ULSS_A1
		cleta
		SESSO
		TITOLO_STUDIO
		STATO_CIVILE
		ISTRUZIONE
		CITTAD
		FLG_TIPO_UTENTE
		ANNO_A1
		ISTRES_IN
	;
run;
/* tengo un record per soggetto */
proc sort nodupkey data=arcipelago1 out=arcipelago1_nodup; by codice_soggetto_bin; run;  

data arcipelago1;
	set arcipelago1_nodup;

	if ULSS_A1=101 THEN
		ULSS_NEW=501;

	if ULSS_A1=102 THEN
		ULSS_NEW=501;

	if ULSS_A1=109 THEN
		ULSS_NEW=502;

	if ULSS_A1=107 THEN
		ULSS_NEW=502;

	if ULSS_A1=108 THEN
		ULSS_NEW=502;

	if ULSS_A1=112 THEN
		ULSS_NEW=503;

	if ULSS_A1=113 THEN
		ULSS_NEW=503;

	if ULSS_A1=114 THEN
		ULSS_NEW=503;

	if ULSS_A1=110 THEN
		ULSS_NEW=504;

	if ULSS_A1=118 THEN
		ULSS_NEW=505;

	if ULSS_A1=119 THEN
		ULSS_NEW=505;

	if ULSS_A1=115 THEN
		ULSS_NEW=506;

	if ULSS_A1=116 THEN
		ULSS_NEW=506;

	if ULSS_A1=117 THEN
		ULSS_NEW=506;

	if ULSS_A1=103 THEN
		ULSS_NEW=507;

	if ULSS_A1=104 THEN
		ULSS_NEW=507;

	if ULSS_A1=106 THEN
		ULSS_NEW=508;

	if ULSS_A1=105 THEN
		ULSS_NEW=508;

	if ULSS_A1=120 THEN
		ULSS_NEW=509;

	if ULSS_A1=121 THEN
		ULSS_NEW=509;

	if ULSS_A1=122 THEN
		ULSS_NEW=509;
	
RUN;

data arcipelago1; set arcipelago1; 
/*dal 2017 ho solo le ulss nuove quindi se sono maggiori di 500 rinomino (creo la variabile ulss_new)*/
if ulss_a1>500 then  ulss_new=ulss_a1; 
run; 
/*e poi qui la metto a missing*/
data arcipelago1; set arcipelago1; 
if ulss_a1>500 then  ulss_a1=.; 
run; 

data arcipelago1;
	retain 
		CODICE_SOGGETTO_BIN
		ULSS_A1
		ULSS_NEW
		ISTRES_IN
		cleta
		SESSO
		ISTRUZIONE
		STATO_CIVILE
		CITTAD
		FLG_TIPO_UTENTE
		ANNO_A1;
	set arcipelago1;
run;

%MEND;



/*per anni <= 2016*/

%ARCIPELAGO_1;

data anno_2015; set arcipelago1; run; 
data anno_2016; set arcipelago1; run; 


/*per anni>=2017*/
%let anno=2017; /*anno di interesse*/
%let fase=12; /*fase di interesse*/

%comuni; 
%SET_ANAGRAFICA_FAR(&anno,&fase);
%ARCIPELAGO_1;

proc sort data=arcipelago1; by istres_in; run; 
proc sort data=comuni_per_merge; by istres_in; run; 
data arcipelago11; merge  arcipelago1 (in=a) comuni_per_merge (in=b); by istres_in; if a ; run; 
/*metto a 999 i soggetti con ulss di residenza fuori veneto*/
data arcipelago11; set arcipelago11; if ulss_a1_comuni =. then ulss_a1_comuni=999; run; 

data arcipelago11; set arcipelago11; drop ulss_a1; run; 
data arcipelago11; set arcipelago11; rename ulss_a1_comuni = ulss_a1; run; 

/*2017*/
data anno_2017; set arcipelago11; ulss_a1_string=put(ulss_a1,3.); run; 
data anno_2017; set anno_2017; drop ulss_a1; run; 
data anno_2017; set anno_2017; rename ulss_a1_string=ulss_a1; run; 

data anno_2017;
	retain 
		CODICE_SOGGETTO_BIN
		ULSS_A1
		ULSS_NEW
		ISTRES_IN
		cleta
		SESSO
		ISTRUZIONE
		STATO_CIVILE
		CITTAD
		FLG_TIPO_UTENTE
		ANNO_A1;
	set anno_2017;
run;

data anno_2017; set anno_2017; run; 

/*2018*/
%let anno=2018;
%let fase=7;
%SET_ANAGRAFICA_FAR(&anno,&fase);
%ARCIPELAGO_1;

proc sort data=arcipelago1; by istres_in; run; 
proc sort data=comuni_per_merge; by istres_in; run; 
data arcipelago11; merge  arcipelago1 (in=a) comuni_per_merge (in=b); by istres_in; if a ; run; 
/*metto a 999 i soggetti con ulss di residenza fuori veneto*/
data arcipelago11; set arcipelago11; if ulss_a1_comuni =. then ulss_a1_comuni=999; run; 

data arcipelago11; set arcipelago11; drop ulss_a1; run; 
data arcipelago11; set arcipelago11; rename ulss_a1_comuni = ulss_a1; run; 

data anno_2018; set arcipelago11; ulss_a1_string=put(ulss_a1,3.); run; 
data anno_2018; set anno_2018; drop ulss_a1; run; 
data anno_2018; set anno_2018; rename ulss_a1_string=ulss_a1; run; 

data anno_2018;
	retain 
		CODICE_SOGGETTO_BIN
		ULSS_A1
		ULSS_NEW
		ISTRES_IN
		cleta
		SESSO
		ISTRUZIONE
		STATO_CIVILE
		CITTAD
		FLG_TIPO_UTENTE
		ANNO_A1;
	set anno_2018;
run;

data anno_2018; set anno_2018; run; 

/*per costruire la tabella con più anni, faccio un append*/
data arcipelago_001; set anno_2015 anno_2016 anno_2017 anno_2018; run; 
/*per accodare fasi successive anno 2018*/
data arcipelago_001; set arcipelago_001 anno_2018; run; 
/*proc freq data=arcipelago_001; table ulss_a1 ulss_new ; run; 
/*eof*/
