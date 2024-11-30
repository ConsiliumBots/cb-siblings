// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Creating inputs for telephonic survey
	// Created: Dec 14, 2023
	// Last Modified: Dec 14, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Data 
// ----------------------------------------------------------------

    import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-09-20.csv", clear
    duplicates drop id_postulante orden rbd cod_curso, force // 0 obs
    unique id_postulante rbd cod_curso  // son únicas
    tempfile datos_jpal
    save `datos_jpal', replace

    import delimited "$main_sae/datos_SAE/1_Source/1_Principal/relaciones/F1_2023-09-20.csv", clear 
    tempfile relaciones
    save `relaciones', replace

    import delimited "$main_sae/datos_SAE/1_Source/1_Principal/oferta/oferta_jpal_j_2023-07-31.csv", clear encoding("utf-8")
    keep rbd cod_curso cod_nivel establecimiento latitud longitud
    rename (latitud longitud)(lat_colegio lon_colegio)
    replace establecimiento = ustrtitle(establecimiento)
    tempfile oferta
    save `oferta', replace

    import delimited "$main_sae/encuesta_telefonica/datos_sae 2023_2022.csv", clear 
    tempfile data_extra
    save `data_extra', replace

// ---------------------------------------------- //
// ------------- RECIBEN LA ENCUESTA ------------ //
// ---------------------------------------------- //

	// nº colegios postulados en común > 0; nº postulantes = 2

	    // 1. Nos quedamos con los apoderados que tienen dos postulantes

            use `datos_jpal', clear
            gen n_hijos = 1
            collapse (min) n_hijos, by(id_apoderado id_postulante)
            collapse (sum) n_hijos, by(id_apoderado)
            tempfile apoderados
            save `apoderados', replace

			use `datos_jpal', clear
			merge m:1 id_apoderado using `apoderados', nogen
			keep if n_hijos == 2

			tempfile postulaciones
			save `postulaciones', replace

    // 2. Nos quedamos con las relaciones con al menos un rbd postulado en común

        // Primero nos quedamos con las relaciones de los apoderados respectivos (solo 2 hijos)

            keep id_apoderado id_postulante
            
            gen auxiliar = 1
            rename id_postulante id_postulante_
            collapse (sum) auxiliar, by(id_apoderado id_postulante_)
            
            drop auxiliar
            bys id_apoderado: gen auxiliar = _n
            reshape wide id_postulante_, i(id_apoderado) j(auxiliar)

            tempfile opcion_1
            save `opcion_1', replace

            rename id_postulante_1 id_postulante
            rename id_postulante_2 id_postulante_1
            rename id_postulante id_postulante_2

            tempfile opcion_2
            save `opcion_2', replace

            use `relaciones', clear
            merge 1:1 id_postulante_1 id_postulante_2 using `opcion_1', gen(_merge_1) keep(1 3)
            merge 1:1 id_postulante_1 id_postulante_2 using `opcion_2', gen(_merge_2) keep(1 4) update

			tab _merge_1 _merge_2 // No hay obs que sean _merge_1 == 3 & _merge_2 == 4, estamos bien
			drop _merge_1 _merge_2

            keep if id_apoderado != ""

            tempfile subconjunto_relaciones
            save `subconjunto_relaciones', replace

        // Viendo las postulaciones: Una observación por id_postulante-rbd

            use `postulaciones', clear
            collapse (min) orden, by(id_postulante rbd)

            bys id_postulante: egen preferencia = rank(orden)

            unique id_postulante preferencia // unique obs

            drop orden

            sum preferencia
            local n_pref = `r(max)'
            dis(`n_pref')

        // Reshape

            rename rbd rbd_1_
            reshape wide rbd_1_ , i(id_postulante) j(preferencia)

            rename id_postulante id_postulante_1

            tempfile rbd_wide_1
            save `rbd_wide_1', replace

            forvalues x = 1/`n_pref' {
                rename rbd_1_`x' rbd_2_`x'
            }

            rename id_postulante_1 id_postulante_2
            tempfile rbd_wide_2
            save `rbd_wide_2', replace

        // Merge con data de relaciones

            use `subconjunto_relaciones', clear
            merge 1:1 id_postulante_1 using `rbd_wide_1', keep(3) nogen
            merge 1:1 id_postulante_2 using `rbd_wide_2', keep(3) nogen

        // Indicador de nº de escuelas en común

            forvalues x = 1/`n_pref' {
                gen is_rbd_1_`x' = 0
                forvalues y = 1/`n_pref' {
                    replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
                }
                replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
                // is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
            }

            gen n_escuelas_comun = 0
            forvalues x = 1/`n_pref' {
                replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_1_`x' != . ) & ( is_rbd_1_`x' != 0 ))
            }

        // Lo pegamos a la data original

            keep id_apoderado postula_en_bloque n_escuelas_comun
            tempfile escuelas_en_comun
            save `escuelas_en_comun', replace

            use `postulaciones', clear
			drop postulacion_familiar
            merge m:1 id_apoderado using `escuelas_en_comun', keep(3) nogen // Los _merge = 1 son personas bajo el mismo apoderado que no son hermanos. 

            // Botamos las observaciones

				drop if n_escuelas_comun == 0

// ---------------------------------------------- //
// ------------------ VARIABLES ----------------- //
// ---------------------------------------------- //

	// 1. Ajustes para crear las variables 

		// Una obs por postulante 

			keep if orden == 1
        
        // Nombres establecimientos y nivel de postulación

            merge m:1 rbd cod_curso using `oferta', keep(3) nogen // pegan todas las obs

		// Falta el id del hermano

			rename id_postulante id_postulante_1
			merge 1:1 id_postulante_1 using `subconjunto_relaciones', gen(_merge_1)
			
			rename id_postulante_2 id_hermano_aux
			rename id_postulante_1 id_postulante_2
			merge 1:1 id_postulante_2 using `subconjunto_relaciones', gen(_merge_2) update
			rename id_postulante_2 id_postulante 

			tab _merge_1 _merge_2
			keep if _merge_1 == 3 | _merge_2 == 4

			gen     id_hermano = id_hermano_aux     if _merge_1 == 3
			replace id_hermano = id_postulante_1    if _merge_2 == 4

			gen     hermano_mayor = 0
			replace hermano_mayor = 1 if _merge_1 == 3
			tab hermano_mayor // mitad son hermano mayor, mitad hermano menor. estamos ok!
		
		// Quedándonos con una obs por relación

			preserve
				keep if hermano_mayor == 0
				keep id_postulante nombre_post establecimiento cod_nivel
				rename (id_postulante nombre_post establecimiento cod_nivel)(id_menor nombre_menor nombre_est_menor cod_nivel_menor)
				tempfile hermanos_menores
				save `hermanos_menores', replace
			restore

			keep if hermano_mayor == 1
			rename id_hermano id_menor
			merge 1:1 id_menor using `hermanos_menores', nogen // pegan todas las obs
            
            rename id_postulante id_mayor

	// 2. Creando variables para todos

        // nombre apoderado

            rename nombre nomApoderado
		
		// nombre_post1 (menor) y nombre_post2 (mayor): nombres postulantes

            rename nombre_menor nombre_post1
            rename nombre_post nombre_post2

		// cant_common_rbd: nº colegios postulados en común

			rename n_escuelas_comun cant_common_rbd

		// school_name1_1 (menor) y school_name1_2 (mayor): nombre colegio primera prefrencia

			gen school_name1_1 = ustrtitle(nombre_est_menor)
			gen school_name1_2 = ustrtitle(establecimiento)

            drop nombre_est_menor establecimiento

        // Niveles: cod_nivel_1 (menor) y cod_nivel_2 (mayor)

            rename cod_nivel_menor cod_nivel_1
            rename cod_nivel cod_nivel_2

        // Label niveles

            gen     label_cod_nivel_1 = "PreKinder"     if cod_nivel_1 == -1
            replace label_cod_nivel_1 = "Kinder"        if cod_nivel_1 == 0
            replace label_cod_nivel_1 = "1ro Básico"    if cod_nivel_1 == 1
            replace label_cod_nivel_1 = "2do Básico"    if cod_nivel_1 == 2
            replace label_cod_nivel_1 = "3ro Básico"    if cod_nivel_1 == 3
            replace label_cod_nivel_1 = "4to Básico"    if cod_nivel_1 == 4
            replace label_cod_nivel_1 = "5to Básico"    if cod_nivel_1 == 5
            replace label_cod_nivel_1 = "6to Básico"    if cod_nivel_1 == 6
            replace label_cod_nivel_1 = "7mo Básico"    if cod_nivel_1 == 7
            replace label_cod_nivel_1 = "8vo Básico"    if cod_nivel_1 == 8
            replace label_cod_nivel_1 = "1ro Medio"     if cod_nivel_1 == 9
            replace label_cod_nivel_1 = "2do Medio"     if cod_nivel_1 == 10
            replace label_cod_nivel_1 = "3ro Medio"     if cod_nivel_1 == 11
            replace label_cod_nivel_1 = "4to Medio"     if cod_nivel_1 == 12

            gen     label_cod_nivel_2 = "PreKinder"     if cod_nivel_2 == -1
            replace label_cod_nivel_2 = "Kinder"        if cod_nivel_2 == 0
            replace label_cod_nivel_2 = "1ro Básico"    if cod_nivel_2 == 1
            replace label_cod_nivel_2 = "2do Básico"    if cod_nivel_2 == 2
            replace label_cod_nivel_2 = "3ro Básico"    if cod_nivel_2 == 3
            replace label_cod_nivel_2 = "4to Básico"    if cod_nivel_2 == 4
            replace label_cod_nivel_2 = "5to Básico"    if cod_nivel_2 == 5
            replace label_cod_nivel_2 = "6to Básico"    if cod_nivel_2 == 6
            replace label_cod_nivel_2 = "7mo Básico"    if cod_nivel_2 == 7
            replace label_cod_nivel_2 = "8vo Básico"    if cod_nivel_2 == 8
            replace label_cod_nivel_2 = "1ro Medio"     if cod_nivel_2 == 9
            replace label_cod_nivel_2 = "2do Medio"     if cod_nivel_2 == 10
            replace label_cod_nivel_2 = "3ro Medio"     if cod_nivel_2 == 11
            replace label_cod_nivel_2 = "4to Medio"     if cod_nivel_2 == 12

        // Establecimientos en común 

            preserve
                use `datos_jpal', clear 
                keep id_postulante rbd orden
                duplicates drop id_postulante rbd, force
                tempfile datos_jpal_v2
                save `datos_jpal_v2', replace 
            restore

            preserve
                keep id_mayor id_menor
                rename id_mayor id_postulante
                merge 1:m id_postulante using `datos_jpal_v2', keep(3) nogen
                rename id_postulante id_mayor
                rename orden orden_mayor

                rename id_menor id_postulante
                merge 1:1 id_postulante rbd using `datos_jpal_v2', keep(3) nogen
                rename id_postulante id_menor
                drop orden

                bys id_mayor id_menor: egen ranking = rank(orden_mayor)
                drop orden_mayor

                reshape wide rbd, i(id_mayor id_menor) j(ranking)
                keep id_mayor id_menor rbd1 rbd2 rbd3
                tempfile colegios_comun
                save `colegios_comun', replace
            restore

            merge 1:1 id_mayor id_menor using `colegios_comun', nogen // all obs _merge = 3

            // Ahora los nombres

                preserve
                    use `oferta', clear
                    keep rbd establecimiento
                    rename establecimiento comun_
                    duplicates drop
                    rename * *1
                    tempfile oferta_1
                    save `oferta_1', replace

                    rename *1 *2
                    tempfile oferta_2
                    save `oferta_2', replace

                    rename *2 *3
                    tempfile oferta_3
                    save `oferta_3', replace
                restore

                merge m:1 rbd1 using `oferta_1', keep(1 3) nogen
                merge m:1 rbd2 using `oferta_2', keep(1 3) nogen
                merge m:1 rbd3 using `oferta_3', keep(1 3) nogen
        
        // Distancia

            geodist lat_colegio lon_colegio latitud longitud, gen(distancia_school_name1)
            gen distancia_hipotetica = distancia_school_name1/2

        // Caso especial: tenemos info del 2022

            preserve
                use `oferta', clear
                keep rbd establecimiento
                duplicates drop
                tempfile oferta_nombres
                save `oferta_nombres', replace
            restore

            preserve
                use `data_extra', clear
                keep if partipa_sae_2022 == 1 & apoderado_2022 == 1
                drop partipa_sae_2022 apoderado_2022
                destring rbd_1p_2022 asignado_1p_2022, replace
                rename rbd_1p_2022 rbd
                merge m:1 rbd using `oferta_nombres', keep(3)

                rename id_postulante id_mayor
                rename establecimiento school_2022_mayor
                rename asignado_1p_2022 asig_1p_2022_mayor
                tempfile caso_mayor
                save `caso_mayor', replace

                rename *_mayor *_menor
                tempfile caso_menor
                save `caso_menor', replace
            restore

            merge 1:1 id_mayor using `caso_mayor', keep(1 3) nogen
            merge 1:1 id_menor using `caso_menor', keep(1 3) nogen

            // Variable caso especial: primer colegio 2022 igual entre hermanos, ninguno fue asignado allí, volvió a postular a ese colegio en 1a pref.

                gen     caso_especial = 0
                replace caso_especial = 1 if school_2022_mayor == school_2022_menor & school_2022_mayor != "" & asig_1p_2022_mayor == 0 & asig_1p_2022_menor == 0 & school_2022_mayor == school_name1_1 & school_2022_mayor == school_name1_2

                gen school1_1_2022 = school_2022_mayor

            // Teléfono 

                drop if telefonomovil == .
                tostring telefonomovil, replace 
                drop if strlen(telefonomovil) != 8

            // Aleatorización hermano 

                count
                local number_obs `r(N)'

                gen     nombre_post = nombre_post1 if _n >= `number_obs'/2
                replace nombre_post = nombre_post2 if _n < `number_obs'/2

// Quedándonos solo con las variables relevantes

    keep telefonomovil id_apoderado id_mayor id_menor nomApoderado nombre_post1 nombre_post2 nombre_post cant_common_rbd school_name1_1 school_name1_2 label_cod_nivel_1 label_cod_nivel_2 comun_* distancia_school_name1 distancia_hipotetica caso_especial school1_1_2022

// Variables para qualtrics 

    gen externaldatareference = id_apoderado
    gen firstname = nomApoderado

    export delimited "$pathData/outputs/telephone_survey/inputs_encuesta.csv", replace                 
