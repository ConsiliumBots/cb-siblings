import delimited "$pathData/inputs/telephone_survey/links_qualtrics.csv", clear
keep externaldatareference link
tempfile links
save `links', replace 

import delimited "$pathData/outputs/telephone_survey/inputs_encuesta.csv", clear                  
merge 1:1 externaldatareference using `links', nogen 

tostring telefonomovil, gen(celular)

replace celular = "+569" + celular