// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Need to create A, B, C and F tables (pre and post feedback)
	// Created: Oct 30, 2023
	// Last Modified: Nov 7, 2023
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- LOOP ------------------- //
// ---------------------------------------------- //

local types "pre post"

foreach x of local types {
	if "`x'" == "pre" {
		global date = "2023-08-30"
		global export = "pre_feedback"
		display "`x'"
	}
	if "`x'" == "post" {
		global date = "2023-09-20"
		global export = "post_feedback"
		display "`x'"
	}

	// ---------------------------------------------- //
	// -------------------- TABLES ------------------ //
	// ---------------------------------------------- //

		// ----------------------------------------------------------------
		// A1
		// ----------------------------------------------------------------
			
			import delimited "$main_sae/datos_SAE/1_Source/1_Principal/oferta/oferta_jpal_j_2023-08-22.csv", clear

			rename (latitud longitud)(lat lon)
			rename total_cupos cupos_totales

			// Enseñanza

				gen cod_ense = real(substr(string(cod_curso, "%30.0g"), 2, 3))

			// Grado

				gen cod_grado = real(substr(string(cod_curso, "%30.0g"), 1, 1))

			// Jornada 

				gen cod_jor = real(substr(string(cod_curso, "%30.0g"), -1, 1))

			// Especialidad

				gen cod_espe = real(substr(string(cod_curso, "%30.0g"), 5, 5))

			// Género 

				gen cod_genero = real(substr(string(cod_curso, "%30.0g"), -2, 1))

				gen 	solo_hombres = 0
				replace solo_hombres = 1 if cod_genero == 2

				gen 	solo_mujeres = 0
				replace solo_mujeres = 1 if cod_genero == 1
			
			// Copago

				gen 	con_copago = 0
				replace con_copago = 1 if valor_cuota > 0

			// Vacantes 

				// Primero necesito ver cuántos preinscritos postulan (regulares y SEP)

					preserve 
						import delimited "$main_sae/datos_SAE/1_Source/1_Principal/prioridades/preinscripcion_jpal_2023-08-01.csv", clear
						tempfile preinscritos
						save `preinscritos', replace

						import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_$date", clear

						collapse (firstnm) orden, by(id_postulante)
						drop orden
						merge 1:1 id_postulante using `preinscritos', keep(3) nogen

						gen preinscritos_postulan = 1
						collapse (sum) preinscritos_postulan prioritario, by(rbd cod_curso)
						rename prioritario preinscritos_postulan_sep
						tempfile preinscritos_postulan
						save `preinscritos_postulan', replace
					restore

				// Generando variables 

					merge 1:1 rbd cod_curso using  `preinscritos_postulan', nogen

					replace preinscritos_postulan = 0 		if preinscritos_postulan == .
					replace preinscritos_postulan_sep = 0 	if preinscritos_postulan_sep == .

					gen 	vacantes = cupos_totales - preinscritos - repitencia_n + repitencia_n_anterior + preinscritos_postulan 
					replace vacantes = 0 if vacantes < 0

					gen vacantes_pie = 0

					gen cupos_prioritarios = round(cupos_totales * 0.15)

					gen 	vacantes_prioritarios = cupos_prioritarios - preinscritos_sep + preinscritos_postulan_sep
					replace vacantes_prioritarios = 0 if vacantes_prioritarios < 0

					gen vacantes_alta_exigencia_t = 0
					gen vacantes_alta_exigencia_r = 0

					gen 	vacantes_regular = vacantes - vacantes_prioritarios
					replace vacantes_regular = 0 if vacantes_regular < 0
					
					gen tiene_orden_pie = 0 
					gen tiene_orden_alta_t = 0

			keep rbd cod_nivel cod_curso cod_ense cod_grado cod_jor cod_espe cod_sede con_copago solo_hombres solo_mujeres lat lon cupos_totales vacantes vacantes_pie vacantes_prioritarios vacantes_alta_exigencia_r vacantes_alta_exigencia_t vacantes_regular
			export delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/$export/A1.csv", replace


		// ----------------------------------------------------------------
		// B1
		// ----------------------------------------------------------------

			import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_$date", clear

			gen 	es_mujer = 0
			replace es_mujer = 1 if genero == "F"

			rename (latitud longitud)(lat_con_error lon_con_error) // da lo mismo que las variables no tengan error porque eso se requiere para la etapa complementaria

			gen calidad_georef = 1		// da lo mismo que las variables no tengan error porque eso se requiere para la etapa complementaria
			
			preserve

			// Alto rendimiento 

				import delimited "$main_sae/datos_SAE/1_Source/1_Principal/otras API risk/ranking_superior_2023-08-01.csv", varnames(1) clear
				tempfile alto_rendimiento
				save `alto_rendimiento', replace

			// Nivel

				import delimited "$main_sae/datos_SAE/1_Source/1_Principal/oferta/oferta_jpal_j_2023-08-22.csv", clear
				keep rbd cod_curso cod_nivel
				tempfile niveles
				save `niveles', replace
			
			restore

			merge m:1 id_postulante using `alto_rendimiento', keep(1 3) 

			gen 	alto_rendimiento = 0
			replace alto_rendimiento = 1 if _merge == 3
			
			merge m:1 rbd cod_curso using `niveles', keep(3) nogen // no _merge = 1 

			bys id_postulante: egen sd_cod_nivel = sd(cod_nivel) // chequeando que sean solo 0s
			tab sd_cod_nivel // = 0

			collapse (firstnm) es_mujer lat_con_error lon_con_error calidad_georef prioritario cod_nivel alto_rendimiento, by(id_postulante)

			gen mrun = _n

			preserve
				keep id_postulante mrun
				export delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/$export/crosswalk_id_mrun.csv", replace
				tempfile crosswalk
				save `crosswalk', replace

			restore

			drop id_postulante

			export delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/$export/B1.csv", replace

		// ----------------------------------------------------------------
		// C1
		// ----------------------------------------------------------------

			import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_$date.csv", clear
			rename neep es_pie 

			// Nivel

				preserve 
					import delimited "$main_sae/datos_SAE/1_Source/1_Principal/oferta/oferta_jpal_j_2023-08-22.csv", clear
					keep rbd cod_curso cod_nivel
					tempfile niveles
					save `niveles', replace
				restore 

				merge m:1 rbd cod_curso using `niveles', keep(3) nogen // no _merge = 1 

			// Prioridad matriculado, agregada por continuidad y preferencia postulante

				gen grado_postulacion = real(substr(string(cod_curso, "%30.0g"), 1, 1))

				preserve
					import delimited "$main_sae/datos_SAE/1_Source/1_Principal/prioridades/preinscripcion_jpal_2023-08-01.csv", clear
					gen grado_mat_aseg = real(substr(string(cod_curso, "%30.0g"), 1, 1))
					drop prioritario
					tempfile prioridad_matriculado
					save `prioridad_matriculado', replace
				restore

				merge 1:1 id_postulante rbd cod_curso using `prioridad_matriculado' 
				* Algunos _merge = 2 deben agregarse, pero otro son de estudiantes que no postularon

				bys id_postulante: egen auxiliar = min(orden)

				drop if _merge == 2 & auxiliar == .
				
				gen     agregada_por_continuidad = 0
				replace agregada_por_continuidad = 1 if _merge == 2

				gen     prioridad_matriculado = 0
				replace prioridad_matriculado = 1 if _merge == 2 | _merge == 3
				drop _merge 

				// Botando las observaciones agregadas por continuidad que no pertenecen al grado de postulación 

					bys id_postulante: ereplace grado_postulacion = mean(grado_postulacion)

					drop if agregada_por_continuidad == 1 & grado_postulacion != grado_mat_aseg
					drop grado_postulacion grado_mat_aseg
					
				// Volvemos a hacer la variable orden

					sort id_postulante orden

					bys id_postulante: gen preferencia_postulante = _n
					drop orden

			// Prioridad hermano

				preserve 
					import delimited "$main_sae/datos_SAE/1_Source/1_Principal/prioridades/prioridad_hermano_2023-08-01.csv", clear
					tempfile prioridad_hermano
					save `prioridad_hermano', replace
				restore

				merge m:1 id_postulante rbd using `prioridad_hermano', keep(1 3)

				gen     prioridad_hermano = 0
				replace prioridad_hermano = 1 if _merge == 3
				drop _merge

			// Prioridad hijo funcionario

				preserve
					import delimited "$main_sae/datos_SAE/1_Source/1_Principal/prioridades/prioridad_funcionario_2023-07-31.csv", clear
					tempfile prioridad_hijo_funcionario
					save `prioridad_hijo_funcionario', replace
				restore

				merge m:1 id_postulante rbd using `prioridad_hijo_funcionario', keep(1 3)
				gen     prioridad_hijo_funcionario = 0
				replace prioridad_hijo_funcionario = 1 if _merge == 3
				drop _merge

			// Prioridad ex alumno

				preserve
					import delimited "$main_sae/datos_SAE/1_Source/1_Principal/prioridades/prioridad_exalumno_2023-07-31.csv", clear
					tempfile prioridad_exalumno
					save `prioridad_exalumno', replace
				restore

				merge m:1 id_postulante rbd using `prioridad_exalumno', keep(1 3)
				gen     prioridad_exalumno = 0
				replace prioridad_exalumno = 1 if _merge == 3
				drop _merge
			
			// Mrun 

				merge m:1 id_postulante using  `crosswalk', nogen
				drop id_postulante

			keep mrun rbd cod_curso cod_nivel preferencia_postulante agregada_por_continuidad es_pie prioridad_*
			export delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/$export/C1.csv", replace
				
		// ----------------------------------------------------------------
		// F1
		// ----------------------------------------------------------------

			import delimited "$main_sae/datos_SAE/1_Source/1_Principal/relaciones/F1_$date.csv", clear
			rename id_postulante_1 id_postulante

			merge m:1 id_postulante using  `crosswalk', keep(3) nogen
			drop id_postulante
			rename mrun mrun_1 
			rename id_postulante_2 id_postulante

			merge m:1 id_postulante using  `crosswalk', keep(3) nogen
			drop id_postulante
			rename mrun mrun_2 

			export delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/$export/F1.csv", replace

}
