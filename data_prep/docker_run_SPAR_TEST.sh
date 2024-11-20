#!/bin/sh

# Wrapper script to initiate the data load
apt update && apt install -y postgresql-common gnupg gnupg2 gnupg1

# Requires postgresql-common
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
  apt install -y postgresql-client-15

# Install poetry and load virtual env
#   - configure poetry cache directory and virtualenvs path, so can be re-used
export POETRY_CACHE_DIR=/application/docker_data/poetry_cache
export POETRY_VIRTUALENVS_PATH=/application/docker_data/poetry_venvs

echo "install poetry"
python3 -m pip install poetry
cd /application
poetry config virtualenvs.create false --local
poetry install
. $(poetry env info --path)/bin/activate
echo "run the data ingestion"

# Run script
python3 ./main_spar_ingest.py TEST
