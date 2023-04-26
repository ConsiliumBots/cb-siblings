// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of applicants
	// Created: 2022
	// Last Modified: Mar 23, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ MAIN STAGE ------ //

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	tempfile asig_reg
	save  `asig_reg', replace

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
	tempfile postulaciones_reg
	save  `postulaciones_reg', replace

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	duplicates report mrun_1 mrun_2
	gen relacion = _n
	tempfile relaciones_reg
	save  `relaciones_reg', replace  // this data has no duplicate relationships. Eg: if mrun_1 = 1 & mrun_2 = 2, there is no observation with mrun_1 = 2 & mrun_2 = 1

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	keep mrun prioritario
	tempfile prioritario
	save  `prioritario', replace

// -------------------------------------------------- //
// ------- 1. STATISTICS ABOUT FAMILY APP. ---------- //
// -------------------------------------------------- //

	* Analysis at student level: only one sibling. 

	use  `relaciones_reg', clear

	reshape long mrun_@ , i(relacion) j(aux)

	gen hermano_mayor = (aux == 1)  // according to the mannual, mrun_1 corresponds to the older sibling when they apply to different levels.
	gen hermano_menor = (aux == 2)  // according to the mannual, mrun_2 corresponds to the younger sibling when they apply to different levels.

	bys relacion: egen double mrun_hermano_men = max(mrun_)
	bys relacion: egen double mrun_hermano_may = min(mrun_)

	gen double mrun_hermano = mrun_hermano_men 		if hermano_mayor == 1 
	replace mrun_hermano = mrun_hermano_may 		if hermano_menor == 1
	replace mrun_hermano = . 						if mrun_hermano == mrun_
	replace mrun_hermano = mrun_hermano_men 		if hermano_menor == 1 & mrun_hermano == .
	replace mrun_hermano = mrun_hermano_may 		if hermano_mayor == 1 & mrun_hermano == .

	count if mrun_ == mrun_hermano // es 0
	drop mrun_hermano_may mrun_hermano_men

	* 506 relationships
	bys mrun_: egen n_relaciones = count(relacion)

	rename mrun_ mrun
	sort relacion mrun
	order mrun

	* Me quedo con el mrun_hermano solo para quienes tienen un hermano: análisis.
	replace mrun_hermano = . if n_relaciones != 1

	unique mrun if n_relaciones == 1 // All obs. are unique

	collapse (max) mismo_nivel postula_en_bloque hermano_* n_relaciones (firstnm) mrun_hermano, by (mrun)
	* Ojo: hay estudiantes que son hermano_mayor == 1 & hermano_menor == 1
	rename n_relaciones n_hermanos
	order n_hermanos

	count if mismo_nivel == 0 & postula_en_bloque == 1 & n_hermanos == 1

	// Priority students that used family application.
		merge 1:1 mrun using `prioritario', keep(1 3) nogen

		tempfile temp
		save  `temp', replace

		use `prioritario', clear
		rename (mrun prioritario)(mrun_hermano prioritario_hermano)
		merge 1:m mrun_hermano using `temp'
		tab mrun_hermano if _merge == 2  // 0 obs. _merge == 2 are no-sibling students. 
		drop if _merge == 1
		drop _merge

		tab postula_en_bloque if prioritario == 1 & n_hermanos == 1 & mismo_nivel == 0
		tab postula_en_bloque if prioritario == 0 & n_hermanos == 1 & mismo_nivel == 0

	// Long of application list
		use `postulaciones_reg', clear
		keep mrun rbd preferencia_postulante cod_nivel
		collapse (min) preferencia_postulante cod_nivel, by(mrun rbd)
		bys mrun: egen order = rank(preferencia_postulante)
		drop preferencia_postulante
		rename order preferencia_postulante

		collapse (max) preferencia_postulante cod_nivel, by(mrun)
		merge 1:1 mrun using `temp', keep(2 3) nogen

		tabstat preferencia_postulante if hermano_menor == 1, stat(mean) by(postula_en_bloque)
		tabstat preferencia_postulante if hermano_mayor == 1, stat(mean) by(postula_en_bloque)


