// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of 2021 and 2022 surveys
	// Created: 2022
	// Last Modified: May 12, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

	if "`c(username)'"=="javieragazmuri" { // Javiera
		global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
		global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
	}

	global pathData "$main/data"

// ----------------------------------------------------------------
// Data clean Survey 2022
// ----------------------------------------------------------------

	import delimited "/Users/javieragazmuri/Downloads/datos_jpal_2022-10-05_enviar.csv", clear 
	bysort id_postulante id_apoderado: generate n_postulante = _n == 1
	keep if n_postulante == 1

	bysort id_apoderado: ereplace n_postulante = sum(n_postulante)

	*keep if n_postulante == 2
	bys id_apoderado: egen prom_post = mean(postulacion_familiar)  // no hay variación a nivel de id_apoderado
	keep id_apoderado postulacion_familiar n_postulante         
	collapse (mean) postulacion_familiar n_postulante, by(id_apoderado)  

	tempfile datos_jpal
	save `datos_jpal', replace

	import delimited "$pathData/inputs/survey/2022/SAE_Encuesta_satisfaccion_2022.csv", clear
	keep if qid1 == "3" // Consent
	merge m:1 id_apoderado using `datos_jpal', keep(1 3) nogen  // solo 33 obs con _merge == 1

	merge m:1 id_apoderado using "$pathData/inputs/survey/2022/MuestraEmails_SIBLINGS.dta", keep(1 3) nogen

// ----------------------------------------------------------------
// Entendimiento postulación familiar
// ----------------------------------------------------------------

	// ----------------------------------------------------------------
	// Q183 ¿Sabes qué pasa cuando marcas "postulación familiar" en el SAE?
	// ----------------------------------------------------------------

	tab q183 postulacion_familiar if q183 != "NA" & n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != .

	// ----------------------------------------------------------------
	// Q184 Por favor, explica con tus propias palabras qué es lo que crees que pasa cuando marcas esta opción (postulación familiar)
	// ----------------------------------------------------------------

	gen categorias = .  
	br q184 categorias if q184!=""       // Hacer el reemplazo a mano
	// categorias == 1 : cambio en el ranking de preferencias
	// categorias == 2 : preferencia a que hijos queden juntos
	// categorias == 3 : prioridad hermano
	// categorias == 4 : postular a más de un niño
	// categorias == 5 : asegura igual matrícula
	// categorias == 6 : todos o ninguno (si sólo uno de los hermanos es admitido pero no hay cupos para el otro, se desecha la asignación del primero y se deja a ambos hermanos sin matrícula)
	// categorias == 7 : otro

	tab categorias postulacion_familiar & n_postulante == 2

// ----------------------------------------------------------------
// Preferencias
// ----------------------------------------------------------------

	// ----------------------------------------------------------------
	// Q213 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la que menos te gusta si quedan en el mismo establecimiento.
	// ----------------------------------------------------------------

	tab q213 postulacion_familiar if q213!="NA" & n_postulante == 2 

	// ----------------------------------------------------------------
	// Q222 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la favorita si quedan en el mismo establecimiento.
	// ----------------------------------------------------------------

	tab q222 postulacion_familiar if q222!="NA" & n_postulante == 2 

	// ----------------------------------------------------------------
	// Q180 Si ambos estudiantes no son admitidos en la misma escuela, ¿qué tan probable es que termines rechazando la vacante?
	// ----------------------------------------------------------------

	destring q180_1, replace ignore(NA)

	gen intervalo = 0 if q180_1<=10 & q180_1!=.
	replace intervalo = 1 if q180_1<=20 & q180_1>10 & q180_1!=.
	replace intervalo = 2 if q180_1<=30 & q180_1>20 & q180_1!=.
	replace intervalo = 3 if q180_1<=40 & q180_1>30 & q180_1!=.
	replace intervalo = 4 if q180_1<=50 & q180_1>40 & q180_1!=.
	replace intervalo = 5 if q180_1<=60 & q180_1>50 & q180_1!=.
	replace intervalo = 6 if q180_1<=70 & q180_1>60 & q180_1!=.
	replace intervalo = 7 if q180_1<=80 & q180_1>70 & q180_1!=.
	replace intervalo = 8 if q180_1<=90 & q180_1>80 & q180_1!=.
	replace intervalo = 9 if q180_1<=100 & q180_1>90 & q180_1!=.

	tab intervalo postulacion_familiar  & n_postulante == 2 

	// ----------------------------------------------------------------
	// Q181 Imagina el caso hipotético en que tu postulante menor queda asignado/a a la escuela de tu primera preferencia pero tu postulante mayor no queda asignado/a ahí.
	// Imagina también que aceptas que esta asignación y matriculas a tus hijo/as en estas escuelas distintas. 
	// ¿Con qué probabilidad crees que, si postulas a tu postulante mayor el siguiente año a la misma escuela que tu hijo/a menor, tu hijo/a mayor quedará asignado a la misma escuela que tu postulante menor?
	// ----------------------------------------------------------------

	destring q181_1, replace ignore(NA)

	gen intervalo_5 = 0 if q181_1<=10 & q181_1!=.
	replace intervalo_5 = 1 if q181_1<=20 & q181_1>10 & q181_1!=.
	replace intervalo_5 = 2 if q181_1<=30 & q181_1>20 & q181_1!=.
	replace intervalo_5 = 3 if q181_1<=40 & q181_1>30 & q181_1!=.
	replace intervalo_5 = 4 if q181_1<=50 & q181_1>40 & q181_1!=.
	replace intervalo_5 = 5 if q181_1<=60 & q181_1>50 & q181_1!=.
	replace intervalo_5 = 6 if q181_1<=70 & q181_1>60 & q181_1!=.
	replace intervalo_5 = 7 if q181_1<=80 & q181_1>70 & q181_1!=.
	replace intervalo_5 = 8 if q181_1<=90 & q181_1>80 & q181_1!=.
	replace intervalo_5 = 9 if q181_1<=100 & q181_1>90 & q181_1!=.

	tab intervalo_5 & n_postulante == 2

	// ----------------------------------------------------------------
	// Q207 Si ambos postulantes quedaran en la misma escuela, ¿Cuál es el establecimiento en que más prefieres que queden asignados?
	// ----------------------------------------------------------------

	tab q207 cant_common_rbd if q207!="NA" // mismo numero de obs si impongo _merge == 3

	destring q207, replace ignore(NA)

	foreach x in 1 2 3 4 5 {
	gen cs_`x'_preferencia_menor = 99
	replace cs_`x'_preferencia_menor = 1 if common_school_`x' == school_name1_1 
	replace cs_`x'_preferencia_menor = 2 if common_school_`x' == school_name2_1
	}

	foreach x in 1 2 3 4 5 {
	gen cs_`x'_preferencia_mayor = 99
	replace cs_`x'_preferencia_mayor =1 if common_school_`x' == school_name1_2
	replace cs_`x'_preferencia_mayor = 2 if common_school_`x' == school_name2_2
	}

	foreach x in 1 2 3 4 5 {
	tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q207 == `x' & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	}
	foreach x in 1 2 3 4 5 {
	tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q207 == `x' & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	}
	// ----------------------------------------------------------------
	// Q216 Si ambos postulantes quedaran en la misma escuela, ¿Cuál es el establecimiento en que menos prefieres que queden asignados?
	// ----------------------------------------------------------------

	tab q216 cant_common_rbd if q216!="NA" // mismo numero de obs si impongo _merge == 3

	destring q216, replace ignore(NA)

	foreach x in 1 2 3 4 5 {
	tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q216 == `x' & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	}

	foreach x in 1 2 3 4 5 {
	tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q216 == `x' & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	}

	// ----------------------------------------------------------------
	// Q212 Si los postulantes quedaran en escuelas distintas, ¿cuál es la asignación que más prefieres?
	// ----------------------------------------------------------------

	tab q212 cant_common_rbd if q212!="NA" 

	destring q212, replace ignore(NA)

	tab cs_1_preferencia_menor cs_2_preferencia_mayor if q212 == 1 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	tab cs_1_preferencia_menor cs_3_preferencia_mayor if q212 == 2 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	tab cs_2_preferencia_menor cs_1_preferencia_mayor if q212 == 3 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	tab cs_2_preferencia_menor cs_3_preferencia_mayor if q212 == 4 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	tab cs_3_preferencia_menor cs_1_preferencia_mayor if q212 == 5 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2
	tab cs_3_preferencia_menor cs_2_preferencia_mayor if q212 == 6 & _merge == 3 & postulacion_familiar == 1 & n_postulante == 2

	tab cs_1_preferencia_menor cs_2_preferencia_mayor if q212 == 1 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	tab cs_1_preferencia_menor cs_3_preferencia_mayor if q212 == 2 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	tab cs_2_preferencia_menor cs_1_preferencia_mayor if q212 == 3 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	tab cs_2_preferencia_menor cs_3_preferencia_mayor if q212 == 4 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	tab cs_3_preferencia_menor cs_1_preferencia_mayor if q212 == 5 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2
	tab cs_3_preferencia_menor cs_2_preferencia_mayor if q212 == 6 & _merge == 3 & postulacion_familiar == 0 & n_postulante == 2

	// ----------------------------------------------------------------
	// Q178 Considerando las dos primeras escuelas en tu ranking para cada hijo/a, ordena estas opciones de asignación del 1 al 5 donde 1 es más prefererida
	// ----------------------------------------------------------------

		destring q178_*, ignore(NA) replace

		* _1 de hijo menor, _2 de hijo mayor 

		// 1. Contar cuántas observaciones perdemos por repetir un mismo colegio entre las preferencias de un mismo estudiante: school_name1_1 == school_name2_1

			count if n_postulante == 2 																			// N total = 4.906
			count if n_postulante == 2 & (school_name1_1 == school_name2_1 | school_name1_2 == school_name2_2) 	// N = 802

			gen 	grupo_interes = 0
			replace grupo_interes = 1 if n_postulante == 2 & school_name1_1 != school_name2_1 & school_name1_2 != school_name2_2 & cant_common_rbd > 0 & cant_common_rbd != .

		// 2. Hay diferentes casos, dependiendo de diferentes combinaciones
			
			* pref1_1 = pref1_2 & pref2_1 = pref2_2 												-> Caso relevante
			count if grupo_interes == 1 & school_name1_1 == school_name1_2 & school_name2_1 == school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 	// N = 2.196 (54%)

			* pref1_1 = pref1_2 & pref2_1 != pref2_2						 						-> Caso relevante
			count if grupo_interes == 1 & school_name1_1 == school_name1_2 & school_name2_1 != school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 	// N = 408 (10%)

			* (pref1_1 != pref1_2 & pref1_1 = pref2_2) & (pref2_1 != pref1_2 & pref2_1 != pref2_2) 	-> Caso relevante
			count if grupo_interes == 1 & school_name1_1 != school_name1_2 & school_name1_1 != school_name2_2 & school_name2_1 != school_name1_2 & school_name2_1 != school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != ""  // N = 439 (11%)

			* pref1_1 != pref1_2 & pref2_1 = pref2_2												-> Caso relevante
			count if grupo_interes == 1 & school_name1_1 != school_name1_2 & school_name2_1 == school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 	// N = 102 (2,5%)

			gen caso = 0 if grupo_interes == 1
			* Caso relevante 1: 1ªs y 2ªs pref. iguales
			replace caso = 1 if grupo_interes == 1 & school_name1_1 == school_name1_2 & school_name2_1 == school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 
			* Caso relevante 2: 1ªs iguales, 2ªs distintas
			replace caso = 2 if grupo_interes == 1 & school_name1_1 == school_name1_2 & school_name2_1 != school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 
			* Caso relevante 3: 1ªs distintas, 2ªs iguales
			replace caso = 3 if grupo_interes == 1 & school_name1_1 != school_name1_2 & school_name2_1 == school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != "" 
			* Caso relevante 4: preferencias distintas
			replace caso = 4 if grupo_interes == 1 & school_name1_1 != school_name1_2 & school_name1_1 != school_name2_2 & school_name2_1 != school_name1_2 & school_name2_1 != school_name2_2 & school_name1_1 != "" & school_name1_2 != "" & school_name2_1 != "" & school_name2_2 != ""  

			* N casos
			tab caso if q178_1 != .

		// 3. Análisis:
			// Promedios
				tabstat q178_1 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat q178_2 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat q178_3 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat q178_4 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat q178_5 if caso == 1, stat(mean) by(postulacion_familiar)

				tabstat q178_1 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat q178_2 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat q178_3 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat q178_4 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat q178_5 if caso == 2, stat(mean) by(postulacion_familiar)

				tabstat q178_1 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat q178_2 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat q178_3 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat q178_4 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat q178_5 if caso == 3, stat(mean) by(postulacion_familiar)

				tabstat q178_1 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat q178_2 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat q178_3 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat q178_4 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat q178_5 if caso == 4, stat(mean) by(postulacion_familiar)

				tabstat q178_1 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat q178_2 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat q178_3 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat q178_4 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat q178_5 if caso == 0, stat(mean) by(postulacion_familiar)

			// % Opción más preferida
				forvalues x = 1/5 {
					gen dummy_`x' = 0 if q178_`x' != .
					replace dummy_`x' = 1 if q178_`x' == 1
				}
				
				tabstat dummy_1 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat dummy_2 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat dummy_3 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat dummy_4 if caso == 1, stat(mean) by(postulacion_familiar)
				tabstat dummy_5 if caso == 1, stat(mean) by(postulacion_familiar)

				tabstat dummy_1 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat dummy_2 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat dummy_3 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat dummy_4 if caso == 2, stat(mean) by(postulacion_familiar)
				tabstat dummy_5 if caso == 2, stat(mean) by(postulacion_familiar)

				tabstat dummy_1 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat dummy_2 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat dummy_3 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat dummy_4 if caso == 3, stat(mean) by(postulacion_familiar)
				tabstat dummy_5 if caso == 3, stat(mean) by(postulacion_familiar)

				tabstat dummy_1 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat dummy_2 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat dummy_3 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat dummy_4 if caso == 4, stat(mean) by(postulacion_familiar)
				tabstat dummy_5 if caso == 4, stat(mean) by(postulacion_familiar)

				tabstat dummy_1 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat dummy_2 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat dummy_3 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat dummy_4 if caso == 0, stat(mean) by(postulacion_familiar)
				tabstat dummy_5 if caso == 0, stat(mean) by(postulacion_familiar)

			// Beneficiados vs perjudicados

				gen contesta = 1 * ((q178_1 + q178_2 + q178_3 + q178_4 + q178_5) != . )

				count if q178_2 > q178_4 & contesta == 1 & caso == 1 & postulacion_familiar == 1 // beneficiados por postulación familiar
				count if q178_2 < q178_4 & contesta == 1 & caso == 1 & postulacion_familiar == 1 // perjudicados por postulación familiar

				count if q178_2 > q178_4 & contesta == 1 & caso == 1 & postulacion_familiar == 0 // se beneficiarían por la postulación familiar
				count if q178_2 < q178_4 & contesta == 1 & caso == 1 & postulacion_familiar == 0 // se verían perjudicados por la postulación familiar


// ----------------------------------------------------------------
// Comportamiento dinámico
// ----------------------------------------------------------------

	// ----------------------------------------------------------------
	// Q225 Si los postulantes quedan asignados en tu opción más preferida, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año? 
	// ----------------------------------------------------------------

	destring q225_1, replace ignore(NA)

	gen intervalo_2 = 0 if q225_1<=10 & q225_1!=.
	replace intervalo_2 = 1 if q225_1<=20 & q225_1>10 & q225_1!=.
	replace intervalo_2 = 2 if q225_1<=30 & q225_1>20 & q225_1!=.
	replace intervalo_2 = 3 if q225_1<=40 & q225_1>30 & q225_1!=.
	replace intervalo_2 = 4 if q225_1<=50 & q225_1>40 & q225_1!=.
	replace intervalo_2 = 5 if q225_1<=60 & q225_1>50 & q225_1!=.
	replace intervalo_2 = 6 if q225_1<=70 & q225_1>60 & q225_1!=.
	replace intervalo_2 = 7 if q225_1<=80 & q225_1>70 & q225_1!=.
	replace intervalo_2 = 8 if q225_1<=90 & q225_1>80 & q225_1!=.
	replace intervalo_2 = 9 if q225_1<=100 & q225_1>90 & q225_1!=.

	tab intervalo_2 postulacion_familiar if n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != .

	// ----------------------------------------------------------------
	// Q227 Si los postulantes no quedan asignados en el mismo establecimiento, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año?
	// ----------------------------------------------------------------

	destring q227_1, replace ignore(NA)

	gen intervalo_3 = 0 if q227_1<=10 & q227_1!=.
	replace intervalo_3 = 1 if q227_1<=20 & q227_1>10 & q227_1!=.
	replace intervalo_3 = 2 if q227_1<=30 & q227_1>20 & q227_1!=.
	replace intervalo_3 = 3 if q227_1<=40 & q227_1>30 & q227_1!=.
	replace intervalo_3 = 4 if q227_1<=50 & q227_1>40 & q227_1!=.
	replace intervalo_3 = 5 if q227_1<=60 & q227_1>50 & q227_1!=.
	replace intervalo_3 = 6 if q227_1<=70 & q227_1>60 & q227_1!=.
	replace intervalo_3 = 7 if q227_1<=80 & q227_1>70 & q227_1!=.
	replace intervalo_3 = 8 if q227_1<=90 & q227_1>80 & q227_1!=.
	replace intervalo_3 = 9 if q227_1<=100 & q227_1>90 & q227_1!=.

	tab intervalo_3 postulacion_familiar if n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != .

	// ----------------------------------------------------------------
	// Q228 Si los postulantes no quedan asignados a tu opción más preferida y no quedan juntos, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año?
	// ----------------------------------------------------------------

	destring q228_1, replace ignore(NA)

	gen intervalo_4 = 0 if q228_1<=10 & q228_1!=.
	replace intervalo_4 = 1 if q228_1<=20 & q228_1>10 & q228_1!=.
	replace intervalo_4 = 2 if q228_1<=30 & q228_1>20 & q228_1!=.
	replace intervalo_4 = 3 if q228_1<=40 & q228_1>30 & q228_1!=.
	replace intervalo_4 = 4 if q228_1<=50 & q228_1>40 & q228_1!=.
	replace intervalo_4 = 5 if q228_1<=60 & q228_1>50 & q228_1!=.
	replace intervalo_4 = 6 if q228_1<=70 & q228_1>60 & q228_1!=.
	replace intervalo_4 = 7 if q228_1<=80 & q228_1>70 & q228_1!=.
	replace intervalo_4 = 8 if q228_1<=90 & q228_1>80 & q228_1!=.
	replace intervalo_4 = 9 if q228_1<=100 & q228_1>90 & q228_1!=.

	tab intervalo_4 postulacion_familiar if n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != .

	// ----------------------------------------------------------------
	// General
	// ----------------------------------------------------------------
	
	label var q225_1 "Asignados en tu opción más preferida"
	label var q227_1 "No asignados juntos"
	label var q228_1 "No asignados en tu opción más preferida y separados"

	label def post_fam 0 "Regular" 1 "Post. Fam."
	label values postulacion_familiar post_fam

	violinplot q227_1 q228_1 if n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != ., split(postulacion_familiar) ///
	 median(msymbol(o))

	// ----------------------------------------------------------------
	// Q223 Si tus hijos quedan en establecimientos distintos luego del proceso principal y complementario SAE, ¿Qué es lo más probable que hagas?
	// ----------------------------------------------------------------

	tab q223 postulacion_familiar if n_postulante == 2 & cant_common_rbd > 0 & cant_common_rbd != .

// ----------------------------------------------------------------
// Beliefs
// ----------------------------------------------------------------

	// ----------------------------------------------------------------
	// Data clean Survey 2021
	// ----------------------------------------------------------------

		import delimited "$pathData/inputs/bases_publicas_SAE_2021_internal_ids/F1_id.csv", clear
		tempfile relaciones_1
		save `relaciones_1', replace

		rename id_postulante_1 id_postulante
		rename id_postulante_2 id_postulante_1
		rename id_postulante id_postulante_2

		tempfile relaciones_2
		save `relaciones_2', replace

		use "$pathData/inputs/survey/2021/preloads/Preloads_appended.dta", clear
		keep id_apoderado id_postulante id_postulante2
		keep if id_postulante2 != ""
		rename id_postulante id_postulante_1
		rename id_postulante2 id_postulante_2

		merge 1:1 id_postulante_1 id_postulante_2 using `relaciones_1', keep(1 3) nogen
		merge 1:1 id_postulante_1 id_postulante_2 using `relaciones_2', update keep(1 4) nogen

		tempfile relaciones_final
		save `relaciones_final', replace

		use "$pathData/inputs/survey/2021/clean_surveySAE2021_siblings.dta", clear
		merge 1:1 id_apoderado using `relaciones_final', keep(3) nogen // no obs in _merge == 1
		count if id_postulante == id_postulante_1 // all obs

		drop if school_name1_1 == school_name2_1
		drop if school_name1_2 == school_name2_2

		gen grupo_interes = 1 if school_name1_1 == school_name1_2 & school_name2_1 == school_name2_2

	// ----------------------------------------------------------------
	// Menor queda asignado en primera preferencia pero mayor no. Probabilidad de que queden juntos el próximo año
	// ----------------------------------------------------------------

		twoway (histogram prob_repostular_hijomayor if postula_en_bloque == 1 & grupo_interes == 1, bin(10) frac color(purple%70))(histogram prob_repostular_hijomayor if postula_en_bloque == 0 & ///
		grupo_interes == 1, bin(10) frac color(orange%70) ytitle("Fracción") xtitle("Probabilidad") legend(label(1 "Post. Fam.") label(2 "Regular")))

	// ----------------------------------------------------------------
	// Probabilidad ambos queden asignados
	// ----------------------------------------------------------------

		replace prob_asign_colegios1y2_4 = . if prob_asign_colegios1y2_4 > 100
		
		label def post_fam 0 "Regular" 1 "Post. Fam."
		label values postula_en_bloque post_fam

		label var prob_asign_colegios1y2_1 "Juntos, 1ª"
		label var prob_asign_colegios1y2_4 "Juntos, 2ª"
		label var prob_asign_colegios1y2_2 "Menor 1ª, Mayor 2ª"
		label var prob_asign_colegios1y2_3 "Menor 2ª, Mayor 1ª"
		label var prob_asign_colegios1y2_5 "Ninguna escuela"

		violinplot prob_asign_colegios1y2_1 prob_asign_colegios1y2_4 prob_asign_colegios1y2_2 prob_asign_colegios1y2_3 if grupo_interes == 1, split(postula_en_bloque)

		// Comparamos con la probabilidad real

			// Data

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
				destring rbd_admitido cod_curso_admitido rbd_admitido_post_resp cod_curso_admitido_post_resp respuesta_postulante_post_lista_, replace
				gen rbd_admitido_ = rbd_admitido
				replace rbd_admitido_ = rbd_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6
				keep mrun rbd_admitido_

				rename (mrun rbd_admitido_)(mrun_1 rbd_admitido_1)
				
				tempfile asig_reg_1
				save  `asig_reg_1', replace

				rename (mrun_1 rbd_admitido_1)(mrun_2 rbd_admitido_2)
				tempfile asig_reg_2
				save  `asig_reg_2', replace			

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
				tempfile postulaciones_reg
				save  `postulaciones_reg', replace

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
				duplicates report mrun_1 mrun_2
				gen relacion = _n
				tempfile relaciones_reg
				save  `relaciones_reg', replace  // this data has no duplicate relationships. Eg: if mrun_1 = 1 & mrun_2 = 2, there is no observation with mrun_1 = 2 & mrun_2 = 1

			// First, we need to eliminate rbd duplicates (and preferences aggregated by continuity) from the students' preferences
				use  `postulaciones_reg', clear

				drop if agregada_por_continuidad == 1

				keep mrun rbd preferencia_postulante cod_nivel

				collapse (min) preferencia_postulante cod_nivel, by(mrun rbd)
				bys mrun: egen order = rank(preferencia_postulante)

				unique mrun order // unique obs
				drop preferencia_postulante
				rename order preferencia_postulante

				rename rbd rbd_1_
			
			// Then, we need the wide form of preferences
				reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
				rename (mrun cod_nivel) (mrun_1 cod_nivel_1)

				tempfile postulaciones_wide
				save  `postulaciones_wide', replace

				forvalues x = 1/78 {
					rename rbd_1_`x' rbd_2_`x'
				}

				rename (mrun_1 cod_nivel_1)(mrun_2 cod_nivel_2)
				tempfile postulaciones_wide_hno
				save  `postulaciones_wide_hno', replace

			// Merging with relationship data
				use  `relaciones_reg', clear
				drop if mismo_nivel == 1
				
				merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
				merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen
				merge m:1 mrun_1 using `asig_reg_1', keep(3) nogen
				merge m:1 mrun_2 using `asig_reg_2', keep(3) nogen

			// Comparing same group

				gen grupo_interes = 1 if rbd_1_1 == rbd_2_1 & rbd_1_2 == rbd_2_2 & rbd_1_1 != rbd_1_2 & rbd_2_1 != rbd_2_2 
			
				tab postula_en_bloque if grupo_interes == 1
				// Ambos primera preferencia
				tab postula_en_bloque if grupo_interes == 1 & rbd_admitido_1 == rbd_admitido_2 & rbd_admitido_1 == rbd_1_1 // 22% reg, 27% bloque
				// Ambos segunda preferencia
				tab postula_en_bloque if grupo_interes == 1 & rbd_admitido_1 == rbd_admitido_2 & rbd_admitido_1 == rbd_1_2 // 7% reg, 11% bloque
				// El menor quede en su primera preferencia, mayor en su segunda
				tab postula_en_bloque if grupo_interes == 1 & rbd_admitido_2 == rbd_2_1 & rbd_admitido_1 == rbd_1_2 & rbd_admitido_1 != rbd_admitido_2 // 4% reg, 1% bloque
				// El menor quede en su segunda preferencia, mayor en su primera
				tab postula_en_bloque if grupo_interes == 1 & rbd_admitido_2 == rbd_2_2 & rbd_admitido_1 == rbd_1_1 & rbd_admitido_1 != rbd_admitido_2 // 1% reg, 1% bloque
				// Ninguno sea admitido en ninguna escuela
				tab postula_en_bloque if grupo_interes == 1 & rbd_admitido_1 == . & rbd_admitido_2 == . // 4% reg, 4% bloque
			
				