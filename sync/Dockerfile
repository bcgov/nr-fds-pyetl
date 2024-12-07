# ----------------- STAGE 1 -----------------
FROM python:3.13-slim-bookworm as base
# using slim for development as the wheels are not always compat with
# alpine, and builds can be slow as a result
# FROM python:3.12-slim as base

ARG DEV=false
ENV VIRTUAL_ENV=/app/docker_venv \
    PATH="/app/docker_venv/bin:$PATH"

# ----------------- STAGE 2 -----------------
FROM base as builder
WORKDIR /app

# Mostly config for poetry
#   - disable prompting
#   - disable virtualenv creation
#   - specify the path to the venv
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=0 \
    POETRY_VIRTUALENVS_CREATE=0 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    VIRTUAL_ENV=/app/docker_venv \
    PATH="/app/docker_venv/bin:$PATH"

# install build tools, and dev libs required to compile postgres stuff
#   ideally these are not going to be used as for most of the libs
#   there are wheels available, however they are available in case we
#   need to compile something
RUN apt update && \
    apt install -y --no-install-recommends gcc libpq-dev python3-dev && \
    useradd -M nonroot

# Install Poetry to global python env
RUN pip install poetry==1.8.4

# Grab the app dependency declarations
COPY pyproject.toml poetry.lock ./

# create the venv in $VIRTUAL_ENV so we can control where it is being created
#  unfortunately this is the only way that we can control the venv that
#  poetry will use, is to create it ourselves
RUN python -m venv $VIRTUAL_ENV; . $VIRTUAL_ENV/bin/activate

# have created and activated the venv, now install the dependencies into it
RUN poetry install --without dev --no-root -v && rm -rf $POETRY_CACHE_DIR

# ----------------- STAGE 3 -----------------
FROM base as runtime
WORKDIR /app


# install the postgres client, required by psycopg2
RUN apt update && apt install -y --no-install-recommends postgresql-client

# only copy over the venv from the builder stage
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# RUN apk add bash
COPY src /app/src


CMD ["python", "src/main.py"]
