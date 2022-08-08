// ================================================================
// ================================================================
*		          		SIBLING SURVEY SAE 2021
// ================================================================
// ================================================================
set more off
clear all

// ----------------------------------------------------------------
// File Description
// ----------------------------------------------------------------
	// Project: 		SAE
	// Objective: 		Analysing Dataset; General Graphs.
	// Created:			JUNE 2022 (AKAC)
	// Last Modified:	JUNE 2022 (AKAC)


// ----------------------------------------------------------------
// Set graph parameters
// ----------------------------------------------------------------
graph set window fontface "Helvetica"
set_defaults graphics

*RBG
// local color1 "17 8 51"
// local color2 "86 39 255"
// local color3 "179 10 242"
// local color4 "154 125 255"
// local color5 "114 232 206"
// local color6 "42 194 178"
// local color7 "34 155 142"
// local color8 "237 23 95"

local color1 "53 42 135"
local color2 "15 92 221"
local color3 "18 125 216"
local color4 "32 179 228"
local color5 "66 237 240"
local color6 "66 243 158"
local color7 "69 240 95"
local color8 "252 208 45"
local color9 "253 229 13"

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

if "`c(username)'"=="antoniaaguilera" { // Antonia Aguilera
  global main = "/Users/antoniaaguilera/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
  global pathData =  "$main/data"
}




// --------- LOAD DATA
import delimited "$pathData/input/survey/Sibling_Joint_Preference_Survey20211025.csv", clear encoding(utf-8)

*  ----- rename variables
replace v6  = "duration_seconds" if _n == 1
replace v42 = "Q14_comentario"   if _n == 1
drop v60
foreach var of varlist * {
  rename `var' `= `var'[1]'
}
rename * , lower
drop if _n<=3
tab progress //todos en 100%
drop startdate enddate status ipaddress duration_seconds finished recordeddate ///
responseid recipientlastname recipientfirstname recipientemail externalreference ///
locationlatitude locationlongitude distributionchannel userlanguage progress

*--------------------------------------------------------------------------------
* Consent
*--------------------------------------------------------------------------------
keep if  q3 == "Sí"
drop q1 q2 q3 type nombre*
count //293

tempfile siblings
save `siblings', replace 

*--------------------------------------------------------------------------------
* q4: Si pudiera matricular a sus hijos al mismos tiempo en la misma escuela,
* ¿cuál sería su primera opción?
*--------------------------------------------------------------------------------
replace q4 = subinstr(q4, "$", "", .)
replace q4 = subinstr(q4, "{e://", "", .)
replace q4 = subinstr(q4, "}", "", .)
replace q4 = subinstr(q4, "Field/", "", .)


split q4, g(q4_)
drop q4_2 q4_4 q4_6

gen q4_cat = 1       if q4_1 == "nombre_post1" & q4_3 == "school_name11" & q4_5 == "nombre_post2" & q4_7 == "school_name12"
replace q4_cat = 2   if q4_1 == "nombre_post1" & q4_3 == "school_name11" & q4_5 == "nombre_post2" & q4_7 == "school_name22"
replace q4_cat = 3   if q4_1 == "nombre_post1" & q4_3 == "school_name21" & q4_5 == "nombre_post2" & q4_7 == "school_name12"
replace q4_cat = 4   if q4_1 == "nombre_post1" & q4_3 == "school_name21" & q4_5 == "nombre_post2" & q4_7 == "school_name22"
replace q4_cat = 5   if q4_1 == "Otra"

label define cat 1 "Ambos en 1º" 2 "Menor en 1º y mayor en 2º" 3 "Menor en 2º y mayor en 1º" 4 "Ambos en 2º" 5 "Otra opción"
label values q4_cat cat
tab q4_cat

preserve 
drop if q4==""
collapse (count) q4_cat, by(q4)

export excel "$pathData/intermediate/survey/q4.xlsx", replace 
restore 
 
* --- plot q4 --- *
count if !mi(q4_cat)
local N: display %6.0fc `r(N)'
gen q4_yes=1 if q16 =="Si"
gen q4_no=1 if q16 =="No"

// graph hbar q4_yes q4_no, over(q4_cat, sort(1) descending label(labsize(small))) blabel(bar, format(%4.1f) size(3.3)) bar(1, color(`color2') lcolor(`color1'))   ///
// graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) margin(l+7 r+15) )  ///
// bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
// yscale(fextend) ytitle("Porcentaje (%)") title("Preferencias sobre Asignación", color(`color1'))
// gr display, xsize(10) ysize(6)
// //
 
// graph export "$figures/pref_assignmentkids.pdf", as(pdf) replace
//cuantos pusieron otra opción, agregar N

*------------------------------------------------------------------------------------
* q10: Ordene sus preferencias de 1 a 5 donde 1 es más preferida y 5 menos preferida
*------------------------------------------------------------------------------------

use `siblings', clear 
count if !mi(q10_1)&!mi(q10_2)&!mi(q10_3)&!mi(q10_4)&!mi(q10_5)
keep if !mi(q10_1)&!mi(q10_2)&!mi(q10_3)&!mi(q10_4)&!mi(q10_5)
//local N: display %6.0fc `r(N)'
//destring q10_*, replace
forval x=1/5 {
	preserve
	gen aux= 1
	destring q10_*, replace
	collapse (sum) count_`x' = aux, by(q10_`x')
	
	gen id = _n
	egen tot_`x'=sum(count_`x')
	gen pc_`x' = count_`x'/tot_`x'*100
	
	tempfile q10_`x'
	save `q10_`x'', replace 
	restore
}
use `q10_1', clear 
merge 1:1 id using `q10_2', nogen
merge 1:1 id using `q10_3', nogen
merge 1:1 id using `q10_4', nogen
merge 1:1 id using `q10_5', nogen

drop if id == 6
gen id_aux = "1º preferencia" if id == 1 
replace id_aux = "2º preferencia" if id == 2
replace id_aux = "3º preferencia" if id == 3
replace id_aux = "4º preferencia" if id == 4
replace id_aux = "5º preferencia" if id == 5

export excel "$pathData/intermediate/survey/q10.xlsx", replace 

// gr hbar count_1 count_2 count_3 count_4 count_5, over(id_aux) stack asyvars percent  ///   
// bar(1, color(`color2'*0.8)) bar(2, color(`color8'*0.8)) bar(3, color(`color4'*0.8)) bar(4, color(`color5'*0.8)) bar(5, color(`color6'*0.8)) /// 
// graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
// bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
// yscale(fextend) ytitle("Porcentaje (%)") ///
// title("Preferencias de Asignación", color("17 8 51")) ///
// legend(order(1 "Ambos en 1º" 2 "Menor en 1º y Mayor en 2º" 3 "Mayor en 2º y Menor en 1º" 4 "Ambos en 2º"  5 "Ninguno es admitido") rows(2))
// //Ver colores de esto
// gr display, xsize(13) ysize(6)
//
// graph export "$figures/pref_assignment.png", as(png) replace
// 
// restore
*------------------------------------------------------------------------------------
* q11: Si ambos estudiantes no son admitidos en la misma escuela, ¿qué tan probable
* es que termine rechazando la vacante y busque otra alternativa
*------------------------------------------------------------------------------------
use `siblings', clear
gen aux = 1
collapse (sum) aux, by(q11_1)

drop if q11_1 == "" 
destring q11_1, replace
sort q11_1
egen tot= sum(aux)
gen pc = aux/tot

egen tot_under10 = sum(pc) if pc<=0.1
gen pc_def = tot_under10
replace pc_def = pc if pc_def==.
replace q11_1=10 if tot_under10!=.

collapse (firstnm) q11_1 tot, by(pc_def)
sort q11_1

export excel "$pathData/intermediate/survey/q11.xlsx", replace 
 
// tw scatter q11_1 pc , mcolor("86 39 255") ///
// graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
// bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
// yscale(fextend) ytitle("Probabilidad de rechazar") xtitle("Proporción") title("Probabilidad de rechazar la vacante", color("17 8 51")) subtitle("Dado que ambos estudiantes no fueron admitidos en la misma escuela", color("17 8 51"))
//
// gr display, xsize(8) ysize(6)
//
// graph export "$figures/prob_rejecting.png", as(png) replace
//
// //ponerle los labels a los % más grandes
// restore

*------------------------------------------------------------------------------------
* q12: El 25 de octubre se anuncian los resultados de la asignación del SAE. 
* ¿Qué tan probable cree que es que: ? 
*------------------------------------------------------------------------------------
use `siblings', clear 
count if !mi(q12_1)&!mi(q12_2)&!mi(q12_3)&!mi(q12_4)&!mi(q12_5)
local N: display %6.0fc `r(N)'

forval x=1/5 {
	preserve
	gen aux= 1
	destring q12_*, replace
	replace q12_`x' = 10  if q12_`x'<=10
	replace q12_`x' = 20  if q12_`x'<=20 & q12_`x' >10
	replace q12_`x' = 30  if q12_`x'<=30 & q12_`x' >20
	replace q12_`x' = 40  if q12_`x'<=40 & q12_`x' >30
	replace q12_`x' = 50  if q12_`x'<=50 & q12_`x' >40
	replace q12_`x' = 60  if q12_`x'<=60 & q12_`x' >50
	replace q12_`x' = 70  if q12_`x'<=70 & q12_`x' >60
	replace q12_`x' = 80  if q12_`x'<=80 & q12_`x' >70
	replace q12_`x' = 90  if q12_`x'<=90 & q12_`x' >80
	replace q12_`x' = 100 if q12_`x'<=100 & q12_`x' >90
	
	
	
	collapse (sum) count_`x' = aux, by(q12_`x')
	
	gen id = _n
	egen tot_`x'=sum(count_`x')
	gen pc_`x' = count_`x'/tot_`x'
	
	tempfile q12_`x'
	save `q12_`x'', replace 
	restore
}

use `q12_1', clear 
merge 1:1 id using `q12_2', nogen
merge 1:1 id using `q12_3', nogen
merge 1:1 id using `q12_4', nogen
merge 1:1 id using `q12_5', nogen

gen tot =`N'
keep q12_* pc_* tot
order pc_* q12_* tot
export excel "$pathData/intermediate/survey/q12.xlsx", replace 

// tw (scatter pc_1 q12_1, mcolor("86 39 255*0.8") )   ///
//    (scatter pc_2 q12_2, mcolor("179 10 242*0.8") )   ///
//    (scatter pc_3 q12_3, mcolor("154 125 255*0.8") )   ///
//    (scatter pc_4 q12_4, mcolor("114 232 206*0.8") )   ///
//    (scatter pc_5 q12_5, mcolor("237 23 95*0.8") ) , ///   
// graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
// bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
// yscale(fextend) ytitle("Frecuencia") xtitle("Probabilidad") title("Creencia en Probabilidad de Asignación", color("17 8 51")) ///
// legend(order(1 "Ambos en 1º" 2 "Menor en 1º y Mayor en 2º" 3 "Mayor en 2º y Menor en 1º" 4 "Ambos en 2º"  5 "Ninguno es admitido"))
// //Ver colores de esto
// gr display, xsize(8) ysize(6)
//
// gr export "$figures/prob_assignment_sae.png", as(png) replace 

*------------------------------------------------------------------------------------
* q13: ¿Sabe qué pasa cuando usted marca "postulación familiar"?
*------------------------------------------------------------------------------------

use `siblings', clear 
gen aux=1
drop if q13==""
collapse (sum) aux , by(q13)

egen tot=sum(aux)
gen pc = aux/tot*100
export excel "$pathData/intermediate/survey/q13.xlsx", replace 

// gr bar , over(q13) ///
// blabel(bar, format(%4.1f) size(3.3)) bar(1, color(`color2') lcolor(`color2'))  ///
// graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
// bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
// yscale(fextend) ytitle("Probabilidad")  title("Conocimiento sobre Postulación Familiar", color("17 8 51")) 
// //Ver colores de esto
// gr display, xsize(8) ysize(6)
//
// gr export "$figures/prob_assignment.png", as(png) replace 

*------------------------------------------------------------------------------------
* q14: Explique con sus propias palabras qué es lo que cree que pasa cuando marca 
* esta opción
*------------------------------------------------------------------------------------

use `siblings', clear 
keep q14 q13
drop if q14==""
replace q14 = subinstr(q14, ",","",.)
replace q14 = subinstr(q14, ".","",.)
replace q14 = subinstr(q14, ";","",.)

 
export excel "$pathData/intermediate/survey/q14.xlsx", replace 

*------------------------------------------------------------------------------------
* q15: ¿Le gustaría que el SAE evaluara sus postulaciones de forma conjunta?
*------------------------------------------------------------------------------------

use `siblings', clear 
 
gen aux=1
drop if q15 ==""
collapse (sum) aux , by(q15)
egen tot = sum(aux)
gen pc = aux/tot*100
export excel "$pathData/intermediate/survey/q15.xlsx", replace 

*------------------------------------------------------------------------------------
* q15_1: Imagina el caso hipotético en que tu hijo menor {} queda asignado a la escuela
* de su primera preferencia {}, pero tu hijo mayor no queda asignado ahí. Imagina
* también que aceptas que esta asignación y matriculas a tus hijos en escuelas distintas.
* ¿Con qué probabilidad crees que, si postulas a tu hijo mayor el siguiente año a la 
* misma escuela que tu hijo menor, tu hijo mayor quedará asignado a la misma escuela 
* que tu hijo menor y finalmente estar juntos?
*------------------------------------------------------------------------------------

use `siblings', clear 

gen aux = 1
keep aux q15_1 
drop if q15_1 == ""
destring q15_1, replace
replace q15_1 = 10 if q15_1  <= 10   
replace q15_1 = 20 if q15_1  <= 20   & q15_1 > 10
replace q15_1 = 30 if q15_1  <= 30   & q15_1 > 20
replace q15_1 = 40 if q15_1  <= 40   & q15_1 > 30
replace q15_1 = 50 if q15_1  <= 50   & q15_1 > 40
replace q15_1 = 60 if q15_1  <= 60   & q15_1 > 50
replace q15_1 = 70 if q15_1  <= 70   & q15_1 > 60
replace q15_1 = 80 if q15_1  <= 80   & q15_1 > 70
replace q15_1 = 90 if q15_1  <= 90   & q15_1 > 80
replace q15_1 = 100 if q15_1 <= 100  & q15_1 > 90

collapse (sum) aux, by(q15_1)

sort q15_1
egen tot= sum(aux)
gen pc = aux/tot

export excel "$pathData/intermediate/survey/q15_1.xlsx", replace 

*------------------------------------------------------------------------------------
* q16: Ya había visto sus resultados de la asignación SAE al momento de la encuesta
*------------------------------------------------------------------------------------

use `siblings', clear 
gen aux = 1
drop if q16==""
collapse (sum) aux, by(q16)
egen tot= sum(aux)
gen pc = aux/tot*100
destring q16, replace

export excel "$pathData/intermediate/survey/q16.xlsx", replace 

