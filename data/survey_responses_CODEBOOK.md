# Codebook: survey_responses.csv

**Dataset**: Survey responses for sibling school allocation study  
**Created**: October 2025  
**Last Modified**: November 2025  
**Source**: SAE 2023 survey data with merged application and school characteristics  
**Unit of Analysis**: Guardian (apoderado) with two siblings applying to schools

---

## Identifiers

| Variable | Type | Description |
|----------|------|-------------|
| `id_apoderado` | string | Unique identifier for the guardian (parent/caretaker) |
| `id_mayor` | string | Unique identifier for the older sibling |
| `id_menor` | string | Unique identifier for the younger sibling |

---

## Survey Response Variables

| Variable | Type | Description | Values |
|----------|------|-------------|--------|
| `cant_common_rbd` | numeric | Number of schools that appear in both siblings' application lists | Integer ≥ 0 |
| `opcion_seleccionada` | string | Option selected by guardian in the survey | "postulacion familiar" (family application) or "postulacion individual" (individual application) |
| `joint_vs_split` | string | Guardian's preference between joint vs best-split scenarios (originally `sibl06_mas`) | Survey response categories | cant_common_rbd == 1
| `worstjoint_vs_split` | string | Guardian's preference between worst-joint vs best-split scenarios (originally `sibl06_menos`) | Survey response categories | cant_common_rbd > 1

---

## School Scenarios

The dataset includes four school choice scenarios:
- **BJ (Best Joint)**: Best school where both siblings could be placed together (from `sibl04_1`)
- **WJ (Worst Joint)**: Worst school where both siblings could be placed together (from `sibl04_2`)
- **BOS (Best Older Solo)**: Best school for older sibling if they attend separately (from `sibl05_mayor`)
- **BYS (Best Younger Solo)**: Best school for younger sibling if they attend separately (from `sibl05_menor`)

### School Names

| Variable | Type | Description |
|----------|------|-------------|
| `bj` | string | Name of the Best Joint school |
| `wj` | string | Name of the Worst Joint school |
| `bos` | string | Name of the Best Older Solo school |
| `bys` | string | Name of the Best Younger Solo school |

---

## School Identifiers (RBD)

| Variable | Type | Description |
|----------|------|-------------|
| `rbd_bj` | numeric | RBD (official school identifier) for Best Joint school |
| `rbd_wj` | numeric | RBD for Worst Joint school |
| `rbd_bos_old` | numeric | RBD for Best Older Solo school |
| `rbd_bos_young` | numeric | RBD for Best Younger Solo school |

---

## School Quality

Quality is measured on a categorical scale from school characteristics data.
0 = no info, 1 = insuficiente, 2 = medio-bajo, 3 = medio, and 4 = alto.

| Variable | Type | Description |
|----------|------|-------------|
| `qual_bj_old` | numeric | Quality category of BJ school for older sibling |
| `qual_bj_young` | numeric | Quality category of BJ school for younger sibling |
| `qual_wj_old` | numeric | Quality category of WJ school for older sibling |
| `qual_wj_young` | numeric | Quality category of WJ school for younger sibling |
| `qual_bos_old` | numeric | Quality category of BOS school for older sibling |
| `qual_bos_young` | numeric | Quality category of BYS school for younger sibling |

**Note on Quality**: Quality values of 0 are treated as missing in the estimation procedures.

---

## Distance (in kilometers)

Distance is calculated from home coordinates to school coordinates using geodist.

| Variable | Type | Description |
|----------|------|-------------|
| `dist_km_bj_old` | numeric | Distance (km) from home to BJ school for older sibling |
| `dist_km_bj_young` | numeric | Distance (km) from home to BJ school for younger sibling |
| `dist_km_wj_old` | numeric | Distance (km) from home to WJ school for older sibling |
| `dist_km_wj_young` | numeric | Distance (km) from home to WJ school for younger sibling |
| `dist_km_bos_old` | numeric | Distance (km) from home to BOS school for older sibling |
| `dist_km_bos_young` | numeric | Distance (km) from home to BYS school for younger sibling |

---

## Preference Order (Orden)

Order indicates the rank position of the school in the guardian's application list (1 = first choice, 2 = second choice, etc.). When a school was repeated in an application (2.13% of cases), the minimum orden was kept.

| Variable | Type | Description |
|----------|------|-------------|
| `orden_bj_old` | numeric | Preference order of BJ school in older sibling's application list |
| `orden_bj_young` | numeric | Preference order of BJ school in younger sibling's application list |
| `orden_wj_old` | numeric | Preference order of WJ school in older sibling's application list |
| `orden_wj_young` | numeric | Preference order of WJ school in younger sibling's application list |
| `orden_bos_old` | numeric | Preference order of BOS school in older sibling's application list |
| `orden_bos_young` | numeric | Preference order of BYS school in younger sibling's application list |

---

## Data Construction Notes

### Sample Selection
1. Started with full SAE 2023 survey responses
2. Filtered to families with siblings (`ensibling == 1`)
3. Removed observations with missing guardian ID (2 obs)
4. Removed observations that didn't answer sibling questions (`sibl04_1 == ""`, 3,716 obs)

### School Information Sources
- School names from survey dropdown menus (joint, younger, older)
- School characteristics merged from program characteristics database
- Application data merged from SAE 2023 application records

### Missing Data
- **BOS and BYS**: ~6% of schools not matched in application data
- **Quality = 0**: Treated as missing in estimation procedures
- **Sibling-specific covariates**: Used separately for each sibling (no averaging)

---

## Related Files

- **Data cleaning script**: `code/7_estimation/clean/1_joint.do`
- **Marginal applications**: `code/7_estimation/clean/2_marginal_applications.do`
- **Likelihood estimation**: `7_estimation/likelihood_functions.py`
- **Estimation script**: `7_estimation/3_estimation.py`

---
 
