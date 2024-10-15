#!/usr/bin/bash
# wrapper script to initiate the data load
echo "install poetry"
python3 -m pip install poetry
cd /application
poetry install
source $(poetry env info --path)/bin/activate
# echo "activate the venv"
# source /venv/bin/activate
echo "run the data ingestion"
python3 ./main_ora_ingest.py TEST
