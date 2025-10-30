import getpass

# Set base path for survey data depending on user
if getpass.getuser() == 'javieragazmuri':
    BASE_PATH = '/Users/javieragazmuri/Library/CloudStorage/Dropbox-ConsiliumBots/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023/'
elif getpass.getuser() == 'tlarroucau':
    BASE_PATH = '/home/tlarroucau/Dropbox/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023/'
else:
    BASE_PATH = '/path/for/other/user/'  # Update as needed

# Data paths
SURVEY_FILE = BASE_PATH + 'encuesta/outputs/responses/SAE_survey_2023_responses_Full_sample.csv'

APPLICANTS = BASE_PATH + 'cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/applications/datos_jpal/datos_jpal_2023_08_28.csv'

PROGRAMS = BASE_PATH + 'cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/oferta/options_feedback_2023_08_28.csv'
