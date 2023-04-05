// ---------------------------------------------- //
// ---------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION --------- //
// ---------------------------------------------- //
// ---------------------------------------------- //

// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of applications
	// Created: 2022
	// Last Modified: Mar 23, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

if "`c(username)'"=="javieragazmuri" { // Javiera
	global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
	global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
  }

global pathData "$main/data"

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

gen double mrun_hermano = mrun_hermano_men if hermano_mayor ==1 
replace mrun_hermano = mrun_hermano_may if hermano_menor ==1
replace mrun_hermano = . if mrun_hermano == mrun_
replace mrun_hermano = mrun_hermano_men if hermano_menor ==1 & mrun_hermano == .
replace mrun_hermano = mrun_hermano_may if hermano_mayor ==1 & mrun_hermano == .

count if mrun_ == mrun_hermano // es 0
drop mrun_hermano_may mrun_hermano_men

* 506 relación
bys mrun_: egen n_relaciones = count(relacion)

rename mrun_ mrun
sort relacion mrun
order mrun

* Me quedo con el mrun_hermano solo para quienes tienen un hermano: análisis.
replace mrun_hermano = . if n_relaciones != 1

collapse (max) mismo_nivel postula_en_bloque hermano_* n_relaciones (firstnm) mrun_hermano, by (mrun)
* Ojo: hay estudiantes que son hermano_mayor == 1 & hermano_menor == 1
rename n_relaciones n_hermanos
order n_hermanos

count if mismo_nivel == 0 & postula_en_bloque == 1 & n_hermanos == 1

merge 1:1 mrun using `prioritario'
drop if _merge == 2
drop _merge

tempfile temp
save  `temp', replace

use `prioritario', clear
rename (mrun prioritario)(mrun_hermano prioritario_hermano)
merge 1:m mrun_hermano using `temp'
tab mrun_hermano if _merge == 2  // 0 obs. _merge == 2 are no-sibling students. 
drop if _merge == 1
drop _merge

* Priority students that used family application.
tab postula_en_bloque if prioritario == 1 & n_hermanos == 1 & mismo_nivel == 0
tab postula_en_bloque if prioritario == 0 & n_hermanos == 1 & mismo_nivel == 0

tempfile hermanos_reg
save  `hermanos_reg', replace

// ---------------------------------------------- //
// ------------- 2. APPLICATIONS ---------------- //
// ---------------------------------------------- //

use  `postulaciones_reg', clear

keep mrun rbd preferencia_postulante cod_nivel
rename rbd rbd_1_
reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
rename mrun mrun_1

tempfile postulaciones_wide
save  `postulaciones_wide', replace

forvalues x = 1/94 {
	rename rbd_1_`x' rbd_2_`x'
}
rename mrun_1 mrun_2
rename cod_nivel cod_nivel_2
tempfile postulaciones_wide_hno
save  `postulaciones_wide_hno', replace

use  `relaciones_reg', clear
merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

drop if mismo_nivel == 1

gen mismo_nivel_educ = 0 
replace mismo_nivel_educ = 1 if cod_nivel < 9 & cod_nivel_2 < 9
replace mismo_nivel_educ = 1 if cod_nivel >= 9 & cod_nivel_2 >= 9

forvalues x = 1/94 {
	gen is_rbd_1_`x' = 0
	forvalues y = 1/94 {
		replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
	}
	replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
	// is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
}

// Nº schools applied in common
	gen n_escuelas_comun = 0
	gen n_postulaciones_mayor = 0
	gen n_postulaciones_menor = 0
		forvalues x = 1/94 {
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

	// Fam. app (and not) for the most common ( n_postulaciones_mayor_final == 2 )
		preserve
		keep if n_postulaciones_mayor_final == 2
		keep if postula_en_bloque == 0
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
		keep if n_postulaciones_mayor_final == 2
		keep if postula_en_bloque == 1
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

	// Siblings applying to the same educational level
		preserve
		keep if n_postulaciones_mayor_final == 2
		keep if postula_en_bloque == 0
		keep if mismo_nivel_educ == 1
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
		keep if n_postulaciones_mayor_final == 2
		keep if postula_en_bloque == 1
		keep if mismo_nivel_educ == 1
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

// Types of schools applied

	// First, we have to match the schools with its characteristics
	forvalues x = 1/94 {
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
			forvalues x = 1/94 {
				replace suma = suma + va_`x' 	if is_rbd_1_`x' != 0 & is_rbd_1_`x' != .
				replace obs = obs + 1 			if is_rbd_1_`x' != 0 & is_rbd_1_`x' != .
			}
			tabstat suma, stat(sum) by(postula_en_bloque)
			tabstat obs, stat(sum) by(postula_en_bloque)  // with both, we construct manually the average value added.

			// Not applied in common
			gen suma_2 = 0
			gen obs_2 = 0
			forvalues x = 1/94 {
				replace suma_2 = suma_2 + va_`x' 	if is_rbd_1_`x' == 0 
				replace obs_2 = obs_2 + 1 			if is_rbd_1_`x' == 0 
			}
			tabstat suma_2, stat(sum) by(postula_en_bloque)
			tabstat obs_2, stat(sum) by(postula_en_bloque)


		// First school

			// Applied in common
			gen valor = 0
			forvalues x = 1/94 {
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
		
	// Comparing with students with no siblings

		use "$pathData/inputs/school_variables/school_program_characteristics_2022.dta", clear
		drop if regexm(rbd, "J") | regexm(rbd, "I") | regexm(rbd, "P")
		keep rbd cod_nivel VA2_AVE performance_category
		collapse (firstnm) VA2_AVE performance_category, by(rbd cod_nivel)
		destring rbd, replace

		tempfile schools_charact
		save `schools_charact', replace

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
		merge m:1 rbd cod_nivel using `schools_charact', keep(1 3) nogen

		merge m:1 mrun using `hermanos_1', keep(1 3) nogen
		merge m:1 mrun using `hermanos_2', keep(1 3) nogen
		
		gen es_hermano_f = 0
		replace es_hermano_f = 1 if es_hermano == 1 | es_hermano_2 == 1

		tabstat VA2_AVE if es_hermano_f == 0 , stat(mean)
		tabstat VA2_AVE if es_hermano_f == 0 & preferencia_postulante == 1 , stat(mean)


