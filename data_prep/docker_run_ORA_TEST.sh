#!/bin/sh

# Install poetry and load virtual env
echo "install poetry"
python3 -m pip install poetry
cd /application
poetry install
. $(poetry env info --path)/bin/activate

# Run script
echo "run the data ingestion"
python3 ./main_ora_ingest.py TEST

