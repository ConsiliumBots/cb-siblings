// ------------------------------------------------------------ //
// ----------------------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION SURVEY 2022 --------- //
// --------------------------------------------------------- //
// -------------------------------------------------------- //

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

if "`c(username)'"=="javieragazmuri" { // Javiera
	global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
	global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
  }

global pathData "$main/data"

// ----------------------------------------------------------------
// Data
// ----------------------------------------------------------------

import delimited "$pathData/inputs/survey/2022/SAE_Encuesta_satisfaccion_2022.csv", clear
keep if qid1 == "3" // Consent 

// ----------------------------------------------------------------
// Q213 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la que menos te gusta si quedan en el mismo establecimiento.
// ----------------------------------------------------------------

tab q213

// ----------------------------------------------------------------
// Q222 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la favorita si quedan en el mismo establecimiento.
// ----------------------------------------------------------------

tab q222

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

tab intervalo

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

tab intervalo_2

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

tab intervalo_3

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

tab intervalo_4

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

tab intervalo_5

