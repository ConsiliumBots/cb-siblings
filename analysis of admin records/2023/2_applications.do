// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of applications
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


// ---------------------------------------------- //
// ------------- 2. APPLICATIONS ---------------- //
// ---------------------------------------------- //

	// First, we need to eliminate rbd duplicates from the students' preferences
		use  `postulaciones_reg', clear

		keep mrun rbd preferencia_postulante cod_nivel
		collapse (min) preferencia_postulante cod_nivel, by(mrun rbd)
		bys mrun: egen order = rank(preferencia_postulante)

		unique mrun order // unique obs
		drop preferencia_postulante
		rename order preferencia_postulante

		rename rbd rbd_1_
	
	// Then, we need the wide form of preferences
		reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
		rename mrun mrun_1

		tempfile postulaciones_wide
		save  `postulaciones_wide', replace

		forvalues x = 1/78 {
			rename rbd_1_`x' rbd_2_`x'
		}
		rename mrun_1 mrun_2
		rename cod_nivel cod_nivel_2
		tempfile postulaciones_wide_hno
		save  `postulaciones_wide_hno', replace

	// Merging with relationship data
		use  `relaciones_reg', clear
		merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
		merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

		drop if mismo_nivel == 1

		gen mismo_nivel_educ = 0 
		replace mismo_nivel_educ = 1 if cod_nivel < 9 & cod_nivel_2 < 9
		replace mismo_nivel_educ = 1 if cod_nivel >= 9 & cod_nivel_2 >= 9

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

		gen n_postulaciones_mayor_final = n_postulaciones_mayor
		replace n_postulaciones_mayor_final = 10 if n_postulaciones_mayor > = 10

		gen n_postulaciones_menor_final = n_postulaciones_menor
		replace n_postulaciones_menor_final = 10 if n_postulaciones_menor > = 10

		tabstat n_escuelas_comun if postula_en_bloque == 1, by(n_postulaciones_menor_final) stat(mean)
		tabstat n_escuelas_comun if postula_en_bloque == 1, by(n_postulaciones_mayor_final) stat(mean)
		tabstat n_escuelas_comun if postula_en_bloque == 0, by(n_postulaciones_menor_final) stat(mean)
		tabstat n_escuelas_comun if postula_en_bloque == 0, by(n_postulaciones_mayor_final) stat(mean)

		gen prop_escuelas_comun_menor = (n_escuelas_comun/n_postulaciones_menor) * 100
		gen prop_escuelas_comun_mayor = (n_escuelas_comun/n_postulaciones_mayor) * 100

		tabstat prop_escuelas_comun_menor prop_escuelas_comun_mayor, by(postula_en_bloque) stat(mean)

			// Histogram

				local start 0
				local width 10

				twoway histogram prop_escuelas_comun_menor if postula_en_bloque == 1,   ///
  				color(purple%70) start(`start') width(`width') frac || ///
  				histogram prop_escuelas_comun_mayor if postula_en_bloque == 1,  ///
  				color(blue%50) start(`start') width(`width') frac ///
  				xtitle("Porcentaje de escuelas postuladas en común") ///
				ytitle("Fracción")  yscale(range(0 1)) ylabel(0 0.2 0.4 0.6 0.8 1) ///
  				title("Postulan en bloque") legend(label(1 "Hermano menor") label(2 "Hermano mayor"))

				twoway histogram prop_escuelas_comun_menor if postula_en_bloque == 0,   ///
  				color(purple%70) start(`start') width(`width') frac || ///
  				histogram prop_escuelas_comun_mayor if postula_en_bloque == 0,  ///
  				color(blue%50) start(`start') width(`width') frac ///
  				xtitle("Porcentaje de escuelas postuladas en común") ///
				ytitle("Fracción")  yscale(range(0 1)) ylabel(0 0.2 0.4 0.6 0.8 1) ///
  				title("Postulación regular") legend(label(1 "Hermano menor") label(2 "Hermano mayor"))
			
	// Relationship between younger and older sibling's applications

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 1

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 2
		tab is_rbd_1_2 if n_postulaciones_mayor_final == 2

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 3
		tab is_rbd_1_2 if n_postulaciones_mayor_final == 3
		tab is_rbd_1_3 if n_postulaciones_mayor_final == 3

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 4
		tab is_rbd_1_2 if n_postulaciones_mayor_final == 4
		tab is_rbd_1_3 if n_postulaciones_mayor_final == 4
		tab is_rbd_1_4 if n_postulaciones_mayor_final == 4

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 5
		tab is_rbd_1_2 if n_postulaciones_mayor_final == 5
		tab is_rbd_1_3 if n_postulaciones_mayor_final == 5
		tab is_rbd_1_4 if n_postulaciones_mayor_final == 5
		tab is_rbd_1_5 if n_postulaciones_mayor_final == 5

		tab is_rbd_1_1 if n_postulaciones_mayor_final == 6
		tab is_rbd_1_2 if n_postulaciones_mayor_final == 6
		tab is_rbd_1_3 if n_postulaciones_mayor_final == 6
		tab is_rbd_1_4 if n_postulaciones_mayor_final == 6
		tab is_rbd_1_5 if n_postulaciones_mayor_final == 6
		tab is_rbd_1_6 if n_postulaciones_mayor_final == 6

	// Sankey graphs

		preserve
			keep if n_postulaciones_mayor_final == 1
			keep is_rbd_1_1
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		preserve
			keep if n_postulaciones_mayor_final == 2
			keep is_rbd_1_1 is_rbd_1_2
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		preserve
			keep if n_postulaciones_mayor_final == 3
			keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		preserve
			keep if n_postulaciones_mayor_final == 4
			keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3 is_rbd_1_4
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		preserve
			keep if n_postulaciones_mayor_final == 5
			keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3 is_rbd_1_4 is_rbd_1_5
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		preserve
			keep if n_postulaciones_mayor_final == 6
			keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3 is_rbd_1_4 is_rbd_1_5 is_rbd_1_6 
			gen aux = _n
			reshape long is_rbd_1_@, i(aux) j(pref_mayor)
			rename is_rbd_1_ pref_menor
			replace aux = 1
			replace pref_menor = 10 if pref_menor > = 10
			collapse (count) aux, by(pref_mayor pref_menor)
			tostring pref_mayor pref_menor, replace
			replace pref_menor = "Not in the preferences" if pref_menor == "0"
			replace pref_menor = "10 o mayor" if pref_menor == "10"
			gen layer = 1
			sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
		restore

		// Fam. app (and not) for the most common ( n_postulaciones_mayor_final == 3 )
			preserve
				keep if n_postulaciones_mayor_final == 3
				keep if postula_en_bloque == 0
				keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3
				gen aux = _n
				reshape long is_rbd_1_@, i(aux) j(pref_mayor)
				rename is_rbd_1_ pref_menor
				replace aux = 1
				replace pref_menor = 10 if pref_menor > = 10
				collapse (count) aux, by(pref_mayor pref_menor)
				tostring pref_mayor pref_menor, replace
				replace pref_menor = "Not in the preferences" if pref_menor == "0"
				replace pref_menor = "10 o mayor" if pref_menor == "10"
				gen layer = 1
				sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
			restore
		
			preserve
				keep if n_postulaciones_mayor_final == 3
				keep if postula_en_bloque == 1
				keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3
				gen aux = _n
				reshape long is_rbd_1_@, i(aux) j(pref_mayor)
				rename is_rbd_1_ pref_menor
				replace aux = 1
				replace pref_menor = 10 if pref_menor > = 10
				collapse (count) aux, by(pref_mayor pref_menor)
				tostring pref_mayor pref_menor, replace
				replace pref_menor = "Not in the preferences" if pref_menor == "0"
				replace pref_menor = "10 o mayor" if pref_menor == "10"
				gen layer = 1
				sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
			restore

		// Siblings applying to the same educational level
			preserve
				keep if n_postulaciones_mayor_final == 3
				keep if postula_en_bloque == 0
				keep if mismo_nivel_educ == 1
				keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3
				gen aux = _n
				reshape long is_rbd_1_@, i(aux) j(pref_mayor)
				rename is_rbd_1_ pref_menor
				replace aux = 1
				replace pref_menor = 10 if pref_menor > = 10
				collapse (count) aux, by(pref_mayor pref_menor)
				tostring pref_mayor pref_menor, replace
				replace pref_menor = "Not in the preferences" if pref_menor == "0"
				replace pref_menor = "10 o mayor" if pref_menor == "10"
				gen layer = 1
				sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
			restore

			preserve
				keep if n_postulaciones_mayor_final == 3
				keep if postula_en_bloque == 1
				keep if mismo_nivel_educ == 1
				keep is_rbd_1_1 is_rbd_1_2 is_rbd_1_3
				gen aux = _n
				reshape long is_rbd_1_@, i(aux) j(pref_mayor)
				rename is_rbd_1_ pref_menor
				replace aux = 1
				replace pref_menor = 10 if pref_menor > = 10
				collapse (count) aux, by(pref_mayor pref_menor)
				tostring pref_mayor pref_menor, replace
				replace pref_menor = "Not in the preferences" if pref_menor == "0"
				replace pref_menor = "10 o mayor" if pref_menor == "10"
				gen layer = 1
				sankey aux, from(pref_mayor) to(pref_menor) by(layer) sortby(name) noval lc(white)
			restore

	// Types of schools applied

		// First, we have to match the schools with its characteristics
			forvalues x = 1/78 {
				preserve
					use "$pathData/inputs/school_variables/school_program_characteristics_2022.dta", clear
					drop if regexm(rbd, "J") | regexm(rbd, "I") | regexm(rbd, "P")
					keep rbd cod_nivel VA2_AVE performance_category
					collapse (firstnm) VA2_AVE performance_category, by(rbd cod_nivel)
					destring rbd, replace
					rename rbd rbd_1_`x'
					rename VA2_AVE va_`x'
					rename performance_category pc_`x'
					tempfile schools_charact_`x'
					save `schools_charact_`x'', replace
				restore

				merge n:1 rbd_1_`x' cod_nivel using `schools_charact_`x'', keep(1 3) nogen
			}
		
		// Value added
		
			// All schools 	
				
				// Applied in common
					gen suma = 0
					gen obs = 0
					forvalues x = 1/78 {
						replace suma = suma + va_`x' 	if is_rbd_1_`x' != 0 & is_rbd_1_`x' != .
						replace obs = obs + 1 			if is_rbd_1_`x' != 0 & is_rbd_1_`x' != .
					}
					tabstat suma, stat(sum) by(postula_en_bloque)
					tabstat obs, stat(sum) by(postula_en_bloque)  // with both, we construct manually the average value added.

				// Not applied in common
					gen suma_2 = 0
					gen obs_2 = 0
					forvalues x = 1/78 {
						replace suma_2 = suma_2 + va_`x' 	if is_rbd_1_`x' == 0 
						replace obs_2 = obs_2 + 1 			if is_rbd_1_`x' == 0 
					}
					tabstat suma_2, stat(sum) by(postula_en_bloque)
					tabstat obs_2, stat(sum) by(postula_en_bloque)


			// First school

				// Applied in common
					gen valor = 0
					forvalues x = 1/78 {
						replace valor = va_`x' 	if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & valor == 0
					}
					replace valor = . if valor == 0

					tabstat valor, stat(mean) by(postula_en_bloque)

				// Not applied in common
					gen valor_2 = 0
					forvalues x = 1/94 {
						replace valor_2 = va_`x' 	if is_rbd_1_`x' == 0 & valor_2 == 0
					}
					replace valor_2 = . if valor_2 == 0

					tabstat valor_2, stat(mean) by(postula_en_bloque)

		// Performance category

			// First school

				// Applied in common
					gen cat_alta_first = .
					forvalues x = 1/78 { 
						replace cat_alta_first = 1 * (pc_`x' == 4) if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & cat_alta_first == .
						replace cat_alta_first = 99 if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & cat_alta_first != . & pc_`x' == .
					}

					replace cat_alta_first = . if cat_alta_first == 99

					tabstat cat_alta_first, stat(mean) by(postula_en_bloque)

				// Not applied in common

					gen cat_alta_first_not = .
					forvalues x = 1/78 { 
						replace cat_alta_first_not = 1 * (pc_`x' == 4) 	if is_rbd_1_`x' == 0 & cat_alta_first_not == . & pc_`x' != .
						replace cat_alta_first_not = 99 				if is_rbd_1_`x' == 0 & cat_alta_first_not == . & pc_`x' == .
					}

					replace cat_alta_first_not = . if cat_alta_first_not == 99

					tabstat cat_alta_first_not, stat(mean) by(postula_en_bloque)

			// All schools

				// Applied in common
					gen cat_alta_acum 	= 0
					gen applied_common 	= 0
					forvalues x = 1/78 { 
						replace cat_alta_acum = cat_alta_acum + 1 * (pc_`x' == 4) if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & cat_alta_acum != .
						replace cat_alta_acum = . if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & pc_`x' == .
						replace applied_common = applied_common + 1 if is_rbd_1_`x' != 0 & is_rbd_1_`x' != .
					}	

					gen rate = cat_alta_acum/applied_common

					tabstat rate, stat(mean) by(postula_en_bloque)

				// Not applied in common

					gen cat_alta_not = 0
					gen not_applied_common = 0
					forvalues x = 1/78 { 
						replace cat_alta_not = 1 * (pc_`x' == 4) 			if is_rbd_1_`x' == 0 & cat_alta_not != .
						replace cat_alta_not = . 							if is_rbd_1_`x' == 0 & pc_`x' == .
						replace not_applied_common = not_applied_common + 1	if is_rbd_1_`x' == 0 
					}

					gen rate_2 = cat_alta_not/not_applied_common

					tabstat rate_2, stat(mean) by(postula_en_bloque)

			// Comparing with students with no siblings

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
				preserve
					collapse (max) es_hermano, by(mrun_1)
					rename mrun_1 mrun
					tempfile hermanos_1
					save `hermanos_1', replace
				restore

				collapse (max) es_hermano, by(mrun_2)
				rename mrun_2 mrun
				rename es_hermano es_hermano_2
				tempfile hermanos_2
				save `hermanos_2', replace

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 

				merge m:1 mrun using `hermanos_1', keep(1 3) nogen
				merge m:1 mrun using `hermanos_2', keep(1 3) nogen
				
				gen es_hermano_f = 0
				replace es_hermano_f = 1 if es_hermano == 1 | es_hermano_2 == 1

				tempfile postulaciones
				save `postulaciones', replace

				use "$pathData/inputs/school_variables/school_program_characteristics_2022.dta", clear
				drop if regexm(rbd, "J") | regexm(rbd, "I") | regexm(rbd, "P")
				keep rbd cod_nivel VA2_AVE performance_category
				collapse (firstnm) VA2_AVE performance_category, by(rbd cod_nivel)
				destring rbd, replace

				tempfile schools_charact
				save `schools_charact', replace

				use `postulaciones', clear
				merge m:1 rbd cod_nivel using `schools_charact', keep(1 3) nogen

				gen cat_alta = 1 * (performance_category == 4) if performance_category != .

				tabstat cat_alta if preferencia_postulante == 1 & es_hermano_f == 0, stat(mean)

				bys mrun: egen prom_cat_alta = mean(cat_alta)

				tabstat prom_cat_alta if preferencia_postulante == 1 & es_hermano_f == 0, stat(mean)

