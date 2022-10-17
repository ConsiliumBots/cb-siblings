// ---------------------------------------------- //
// ---------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION --------- //
// ---------------------------------------------- //
// ---------------------------------------------- //

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
global pathData "$main/data"

// --------------------------------------------- //
// ------------------ HERMANOS ----------------- //
// --------------------------------------------- //

// --------- ETAPA REGULAR ----------  //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear

duplicates report mrun_1 mrun_2
bys mrun_1: egen n_hermanos_reg = count(mrun_2)
rename (mismo_nivel postula_en_bloque)(mismo_nivel_reg postula_en_bloque_reg)

tempfile hermanos_reg
save  `hermanos_reg', replace

// --------- ETAPA COMPLEMENTARIA ----------  //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/F2_Relaciones_entre_postulantes_etapa_complementaria_2021_Admisión_2022_PUBL.csv", clear

bys mrun_1: egen n_hermanos_comp = count(mrun_2)
rename (mismo_nivel postula_en_bloque)(mismo_nivel_comp postula_en_bloque_comp)

merge 1:1 mrun_1 mrun_2 using `hermanos_reg'
tab postula_en_bloque_comp if _merge== 3

gen hermano_reg  = (_merge == 2 | _merge == 3 )
gen hermano_comp = (_merge == 1 | _merge == 3)

drop _merge
gen relacion = _n

reshape long mrun_@ , i(relacion) j(aux)

gen hermano_mayor = (aux == 1)
gen hermano_menor = (aux == 2)

bys mrun_: egen n_relaciones = count(relacion)

sort relacion mrun
rename mrun_ mrun
order mrun

duplicates report mrun
collapse (firstnm) mismo_nivel* postula_en_bloque* n_hermanos_* hermano_* , by (mrun)

gen mismo_nivel = (mismo_nivel_reg == 1 | mismo_nivel_comp == 2)


tempfile hermanos
save `hermanos', replace

// --------------------------------------------- //
// ---------------- POSTULANTES ---------------- //
// --------------------------------------------- //

// --------- ETAPA REGULAR ----------  //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admision_2022_PUBL.csv", clear
//461,223
keep mrun prioritario alto_rendimiento

tempfile postulantes_reg
save `postulantes_reg', replace

// --------- ETAPA COMPLEMENTARIA ----------  //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/B2_Postulantes_etapa_complementaria_2021_Admision_2022_PUBL.csv", clear
//108,119
keep mrun prioritario alto_rendimiento

merge 1:1 mrun using `postulantes_reg'

gen postula_reg  = (_merge == 2 | _merge == 3)
gen postula_comp = (_merge == 1 | _merge == 3)

drop _merge

merge 1:1 mrun using `hermanos'
replace hermano_reg = 0    if hermano_reg  == .
replace hermano_comp = 0   if hermano_comp == .
unique(mrun)
count if postula_reg == 1 & postula_comp == 1

// ---------------------------------------------- //
// ------------------ ANÁLISIS ------------------ //
// ---------------------------------------------- //
* --- cómo son los que postulan en bloque en comparación con los que no (prioritarios)
preserve
*etapa regular
keep if hermano_reg == 1
drop *_comp
drop mismo_nivel
rename *_reg *
collapse (mean) prioritario mismo_nivel n_hermanos hermano_mayor hermano_menor, by(postula_en_bloque)
gen etapa = "reg"
tempfile aux_reg
save `aux_reg', replace
restore

preserve
*etapa regular
keep if hermano_comp == 1
drop *_reg
drop mismo_nivel
rename *_comp *
collapse (mean) prioritario mismo_nivel n_hermanos hermano_mayor hermano_menor, by(postula_en_bloque)
gen etapa = "comp"

append using `aux_reg'
gsort -etapa postula_en_bloque
export excel "$pathData/outputs/analysis-2021/comparacion_bloque.xlsx", replace first(variables)
restore

* --- postula sólo en ambas etapas
gen trayectoria = 1 ///
if (postula_reg == 1 & hermano_reg == 0) & (postula_comp ==  1 & hermano_comp == 0)
* --- postula sólo en regular y con hermanos en complementaria, pero no en bloque.
replace trayectoria = 2 ///
if (postula_reg == 1 & hermano_reg == 0) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 0)
* --- postula sólo en regular y con postulación en bloque en complementaria
replace trayectoria = 3 ///
if (postula_reg == 1 & hermano_reg == 0) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 1)

* --- postula hermanos no en bloque en regular, solo en complementaria
replace trayectoria = 4 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 0) & (postula_comp == 1 & hermano_comp == 0)
* --- postula hermanos no en bloque en regular, hermanos no en bloque en complementaria
replace trayectoria = 5 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 0) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 0)
* --- postula hermanos no en bloque en regular, hermanos en bloque en complementaria
replace trayectoria = 6 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 0) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 1)

* --- postula hermanos en bloque en regular, solo en complementaria
replace trayectoria = 7 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 1) & (postula_comp == 1 & hermano_comp == 0)
* --- postula hermanos en bloque en regular, hermanos sin bloque en complementaria
replace trayectoria = 8 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 1) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 0)
* --- postula hermanos en bloque en regular, en bloque en complementaria
replace trayectoria = 9 ///
if (postula_reg == 1 & hermano_reg == 1 & postula_en_bloque_reg == 1) & (postula_comp == 1 & hermano_comp == 1 & postula_en_bloque_comp == 1)


collapse (count) mrun  ,by(trayectoria)

*drop if trayectoria == .

gen inicio = 1     if trayectoria <=3
replace inicio = 2 if trayectoria == 4 | trayectoria == 5 | trayectoria == 6
replace inicio = 3 if trayectoria == 7 | trayectoria == 8 | trayectoria == 9

gen fin = 4      if trayectoria == 1 | trayectoria == 4 | trayectoria == 7
replace fin = 5  if trayectoria == 2 | trayectoria == 5 | trayectoria == 8
replace fin = 6  if trayectoria == 3 | trayectoria == 6 | trayectoria == 9

rename mrun frecuencia

bys inicio: egen n_inicio = sum(frecuencia)
bys fin: egen n_fin = sum(frecuencia)

sort trayectoria

export excel "$pathData/outputs/analysis-2021/trayectorias.xlsx", replace first(variables)

// ----------------------------------------------- //
// ---------------- POSTULACIONES ---------------- //
// ----------------------------------------------- //
* son diferentes los rankings de los que postulan en bloque vs los que no ?

// --------- ETAPA REGULAR ----------  //
import delimited  "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admision_2022_PUBL.csv", clear
bys mrun: egen n_postulaciones = count(preferencia_postulante)

merge m:1 mrun using `hermanos'
keep if _merge == 3
drop _merge

gen etapa = "reg"

tempfile postulaciones_reg
save `postulaciones_reg', replace

// --------- ETAPA COMPLEMENTARIA ----------  //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/C2_Postulaciones_etapa_complementaria_2021_Admision_2022_PUBL.csv", clear
bys mrun: egen n_postulaciones = count(preferencia_postulante)

merge m:1 mrun using `hermanos'
keep if _merge == 3
drop _merge

gen etapa = "comp"

append using `postulaciones_reg'

gsort -etapa mrun

mdesc hermano_mayor

*gen mismo_nivel = 1 if (mismo_nivel_reg == 1 | mismo_nivel_comp == 1)
*br if mismo_nivel == 1 & largo_sinbloque == 1

* ----
gen largo_sinbloque = 1 if ((hermano_reg == 1 & postula_en_bloque_reg == 0) | (hermano_comp == 1 & postula_en_bloque_comp == 0))
gen largo_conbloque = 1 if ((hermano_reg == 1 & postula_en_bloque_reg == 1) | (hermano_comp == 1 & postula_en_bloque_comp == 1))

collapse (sum) largo* (firstnm) hermano_mayor mismo_nivel , by(mrun etapa)
replace largo_sinbloque = . if largo_sinbloque == 0
replace largo_conbloque = . if largo_conbloque == 0

preserve
collapse (mean) largo*, by(hermano_mayor)
gen cat = "Hermanos Menores"     if hermano_mayor == 0
replace cat = "Hermanos Mayores" if hermano_mayor == 1

tempfile mayor
save `mayor', replace
restore

collapse (mean) largo*, by(mismo_nivel)
gen cat = "Distinto Nivel"  if mismo_nivel == 0
replace cat = "Mismo Nivel" if mismo_nivel == 1
drop mismo_nivel

append using `mayor'
format largo_sinbloque largo_conbloque %5.3f

export excel "$pathData/outputs/analysis-2021/rankings.xlsx", replace first (variables)

// ----------------------------------------------- //
// ---------------- ASIGNACIONES ----------------- //
// ----------------------------------------------- //
* cómo fue la asignación de los que postularon en bloque vs los que no

// ------ ETAPA REGULAR ------ //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admision_2022_PUBL.csv", clear charset(utf-8)
rename respuesta_postulante_post_lista_ respuesta_post_lista
rename * *_reg
rename mrun_reg mrun

tempfile resultados_regular
save `resultados_regular', replace

// ------ ETAPA COMPLEMENTARIA ------ //
import delimited "$pathData/inputs/analysis-2021/SAE_2021/D2_Resultados_etapa_complementaria_2021_Admision_2022_PUBL.csv", clear charset(utf-8)
rename * *_comp
rename mrun_comp mrun

merge 1:1 mrun using `resultados_regular'

order mrun *_reg *_comp

gen rbd_final = ""
gen cod_curso_final = ""
gen asignado_comp = 0
destring respuesta_post_lista_reg, replace
gen asignado_en = ""

* --- estudiantes que acepta en etapa regular
tab _merge if respuesta_postulante_reg == 1 //no hay ninguno que acepte y que estén en complementaria
replace rbd_final = rbd_admitido_reg               if respuesta_postulante_reg == 1
replace cod_curso_final = cod_curso_admitido_reg   if respuesta_postulante_reg == 1
replace asignado_en = "regular"                    if respuesta_postulante_reg == 1

* --- estudiantes que acepta y espera en etapa regular
tab _merge if respuesta_postulante_reg == 2 //no hay ninguno que acepte y que estén en complementaria
tab respuesta_post_lista_reg if respuesta_postulante_reg == 2 //respuesta post lista sólo ==1
* acepta lista de espera
replace rbd_final       = rbd_admitido_post_resp_reg           if respuesta_postulante_reg == 2 & respuesta_post_lista_reg == 1
replace cod_curso_final = cod_curso_admitido_post_resp_reg     if respuesta_postulante_reg == 2 & respuesta_post_lista_reg == 1
replace asignado_en     = "regular"                            if respuesta_postulante_reg == 2 & respuesta_post_lista_reg == 1
* --- estudiantes estudiantes que rechazan
tab _merge if respuesta_postulante_reg == 3
* los que están sólo en regular
replace rbd_final       = "rechaza-en-regular"    if respuesta_postulante_reg == 3 & _merge == 2
replace cod_curso_final = "rechaza-en-regular"    if respuesta_postulante_reg == 3 & _merge == 2
replace asignado_en     = "regular"               if respuesta_postulante_reg == 3 & _merge == 2

* los que están en ambas, si rechaza en primera está obligado a aceptar en complementaria
replace rbd_final       = rbd_admitido_comp       if respuesta_postulante_reg == 3 & _merge == 3
replace cod_curso_final = cod_curso_admitido_comp if respuesta_postulante_reg == 3 & _merge == 3
replace asignado_en     = "complementaria"        if respuesta_postulante_reg == 3 & _merge == 3

* --- estudiantes que rechazan y espera
tab _merge if respuesta_postulante_reg == 4 //no obs

* --- estudiantes que no responden
tab _merge if respuesta_postulante_reg == 5

replace rbd_final       = rbd_admitido_reg       if respuesta_postulante_reg == 5
replace cod_curso_final = cod_curso_admitido_reg if respuesta_postulante_reg == 5
replace asignado_en     = "regular"              if respuesta_postulante_reg == 5

* --- estudiantes que están obligados a esperar
tab _merge if respuesta_postulante_reg == 6
tab respuesta_post_lista_reg if respuesta_postulante_reg == 6 & _merge == 2
tab respuesta_post_lista_reg if respuesta_postulante_reg == 6 & _merge == 3

* espera, se le asigna y acepta
replace rbd_final       = rbd_admitido_post_resp_reg if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 1
replace cod_curso_final = cod_curso_admitido_reg     if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 1
replace asignado_en     = "regular"                  if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 1

* espera, se le asigna y rechaza
replace rbd_final       = "sale-del-proceso"         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 2
replace cod_curso_final = "sale-del-proceso"         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 2
replace asignado_en     = "regular"                  if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 2

replace rbd_final       = rbd_admitido_comp          if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 3
replace cod_curso_final = cod_curso_admitido_comp    if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 3
replace asignado_en     = "complementaria"           if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 3 & _merge == 3

* obligado a esperar y sin respuesta post lista
replace rbd_final       = rbd_admitido_post_resp_reg        if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 5 & _merge == 2
replace cod_curso_final = cod_curso_admitido_post_resp_reg  if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 5 & _merge == 2
replace asignado_en     = "regular"                         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 5 & _merge == 2

* obligado a esperar y sin asignacion
replace rbd_final       = "sin-asignacion"         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 2
replace cod_curso_final = "sin-asignacion"         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 2
replace asignado_en     = "regular"                if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 2

replace rbd_final       = rbd_admitido_comp         if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 3
replace cod_curso_final = cod_curso_admitido_comp   if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 3
replace asignado_en     = "complementaria"          if respuesta_postulante_reg == 6 & respuesta_post_lista_reg == 6 & _merge == 3

* --- estudiantes que salen del proceso
replace rbd_final       = "sale-del-proceso"  if respuesta_postulante_reg == 7
replace cod_curso_final = "sale-del-proceso"  if respuesta_postulante_reg == 7
replace asignado_en     = "regular"           if respuesta_postulante_reg == 7

* ------------------------------- *
* ------ ETAPA COMPLEMENTARIA --- *
* ------------------------------- *
count if rbd_final == "" & _merge == 1 // 73,395
count if rbd_final == "" & _merge == 2 // 0
count if rbd_final == "" & _merge == 3 // 0

replace rbd_final = rbd_admitido_comp                  if _merge == 1
replace cod_curso_final =  cod_curso_admitido_comp     if _merge == 1
replace asignado_en = "complementaria"                 if _merge == 1

replace rbd_final = subinstr(rbd_final, " ", "", .)
replace cod_curso_final = subinstr(cod_curso_final, " ", "", .)

* ------------------------------- *
* ------ ETAPA COMPLEMENTARIA --- *
* ------------------------------- *
replace rbd_final       = "sin-asignacion" if rbd_final == ""
replace cod_curso_final = "sin-asignacion" if cod_curso_final == ""
replace asignado_en     = "sin-asignacion" if rbd_final == ""

gsort -rbd_final
gen situacion_final     = "Sin Asignación"              if rbd_final == "sin-asignacion"
replace situacion_final = "Sale del Proceso"            if rbd_final == "sale-del-proceso"
replace situacion_final = "Rechaza en Regular"          if rbd_final == "rechaza-en-regular"
replace situacion_final = "Asignado en Regular"         if rbd_final != "sin-asignacion" & rbd_final !="sale-del-proceso" & rbd_final != "rechaza-en-regular" & asignado_en == "regular"
replace situacion_final = "Asignado en Complementaria"  if rbd_final != "sin-asignacion" & rbd_final !="sale-del-proceso" & rbd_final != "rechaza-en-regular" & asignado_en == "complementaria"
mdesc situacion_final
mdesc asignado_en
br if asignado_en == ""
keep mrun rbd_final cod_curso_final situacion_final asignado_en
duplicates report mrun
merge 1:1 mrun using `hermanos'
keep if _merge == 3

gen en_bloque = 1        if  postula_en_bloque_reg  == 1 & asignado_en == "regular"
replace en_bloque =  1   if  postula_en_bloque_comp == 1 & asignado_en == "complementaria"
replace en_bloque =  0   if  postula_en_bloque_reg  == 0 & asignado_en == "regular"
replace en_bloque =  0   if  postula_en_bloque_comp == 0 & asignado_en == "complementaria"
//los que tienen missing son los que cambian su postulación por una postulación individual
br
mdesc en_bloque
collapse (count) mrun, by(situacion_final en_bloque)
bys situacion_final: egen total = sum(mrun)

replace en_bloque = 2 if en_bloque == .
*drop if en_bloque == 2
reshape wide mrun@ total@, i(situacion_final) j(en_bloque)
br
sort situacion_final mrun0 mrun1 total0
rename mrun0 no_en_bloque
rename mrun1 si_en_bloque
*rename total0 total
drop total*
gen total = no_en_bloque + si_en_bloque

order situacion_final no_en_bloque si_en_bloque total

*set obs 6
egen tot_no_bloque = sum(no_en_bloque)
egen tot_si_bloque = sum(si_en_bloque)

*replace situacion_final = "Total"        if _n == 6
*replace no_en_bloque = tot_no_bloque     if _n == 6
*replace si_en_bloque = tot_si_bloque     if _n == 6

*replace no_en_bloque = no_en_bloque/tot_no_bloque*100 if _n<=5
*replace si_en_bloque = si_en_bloque/tot_si_bloque*100 if _n<=5
replace no_en_bloque = no_en_bloque/total*100
replace si_en_bloque = si_en_bloque/total*100

export excel "$pathData/outputs/analysis-2021/asignaciones.xlsx", replace first (variables)
