// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of applicants
	// Created: 2022
	// Last Modified: June 27, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ MAIN STAGE ------ //

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
// ---------------- 0. DATA CLEAN ------------------- //
// -------------------------------------------------- //

	// First, we need to eliminate rbd duplicates (and preferences aggregated by continuity) from the students' preferences
		use  `postulaciones_reg', clear

		bys mrun: egen tiene_mat_aseg = max(prioridad_matriculado)

		gen 	rbd_matriculado = 0
		replace rbd_matriculado = rbd if prioridad_matriculado == 1
		bys mrun: ereplace rbd_matriculado = max(rbd_matriculado)

		drop if agregada_por_continuidad == 1

		keep mrun rbd preferencia_postulante cod_nivel tiene_mat_aseg rbd_matriculado

		collapse (min) preferencia_postulante cod_nivel (max) tiene_mat_aseg rbd_matriculado, by(mrun rbd)
		bys mrun: egen order = rank(preferencia_postulante)

		unique mrun order // unique obs
		drop preferencia_postulante
		rename order preferencia_postulante

		rename rbd rbd_1_
	
	// Then, we need the wide form of preferences
		reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
		rename (mrun cod_nivel tiene_mat_aseg rbd_matriculado) (mrun_1 cod_nivel_1 tiene_mat_aseg_1 rbd_matriculado_1)

		tempfile postulaciones_wide
		save  `postulaciones_wide', replace

		forvalues x = 1/78 {
			rename rbd_1_`x' rbd_2_`x'
		}

		rename (mrun_1 cod_nivel_1 tiene_mat_aseg_1 rbd_matriculado_1)(mrun_2 cod_nivel_2 tiene_mat_aseg_2 rbd_matriculado_2)
		tempfile postulaciones_wide_hno
		save  `postulaciones_wide_hno', replace

	// Merging with relationship data
		use  `relaciones_reg', clear
		merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
		merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

		forvalues x = 1/78 {
			gen is_rbd_1_`x' = 0
			forvalues y = 1/78 {
				replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
			}
			replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
			// is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
		}

	// Nº schools applied in common
		gen n_escuelas_comun = 0
		gen n_postulaciones_mayor = 0
		gen n_postulaciones_menor = 0
		forvalues x = 1/78 {
			replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_1_`x' != . ) & ( is_rbd_1_`x' != 0 ))
			replace n_postulaciones_mayor = n_postulaciones_mayor + ( rbd_1_`x' != . )
			replace n_postulaciones_menor = n_postulaciones_menor + ( rbd_2_`x' != . )
		}

// -------------------------------------------------- //
// ---------------- 1. STATISTICS ------------------- //
// -------------------------------------------------- //

	// N relationships excluded because they are from the same level

		tab mismo_nivel

	// N relationships excluded because they did not apply to anything in common

		count
		count if n_escuelas_comun == 0

// -------------------------------------------------- //
// -------------- 2. RELATIONSHIPS ------------------ //
// -------------------------------------------------- //

	// Appendix: relationship between levels

		tab cod_nivel_1 cod_nivel_2

	// Fam. app. and secure enrollment

		gen 	mat_asegurada_mismo_col = 0
		replace mat_asegurada_mismo_col = 1 if tiene_mat_aseg_1 == 1 & tiene_mat_aseg_2 == 1 & rbd_matriculado_1 == rbd_matriculado_2

		tab mat_asegurada_mismo_col postula_en_bloque
