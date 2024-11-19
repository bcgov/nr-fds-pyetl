#!/bin/sh

# Install poetry and load virtual env
echo "install poetry"
python3 -m pip install poetry
cd /application

# configure poetry cache directory and virtualenvs path
export POETRY_CACHE_DIR=/application/docker_data/poetry_cache
export POETRY_VIRTUALENVS_PATH=/application/docker_data/poetry_venvs

poetry install
. $(poetry env info --path)/bin/activate

# Run script
echo "run the data ingestion"
python3 ./main_ora_ingest.py TEST

