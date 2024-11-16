#!/usr/bin/bash
# wrapper script to initiate the data load
apt-get update && apt-get --assume-yes install postgresql-common gnupg gnupg2 gnupg1 && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && apt-get --assume-yes install postgresql-client-15

echo "install poetry"
python3 -m pip install poetry
cd /application
poetry install
source $(poetry env info --path)/bin/activate

# echo "activate the venv"
# source /venv/bin/activate
echo "run the data ingestion"
python3 ./main_spar_ingest.py TEST
