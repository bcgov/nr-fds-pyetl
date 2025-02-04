# Overview

Scripts / code used to:
* pull data from on prem oracle databases to object storage
* push data from object storage to containerized oracle
* pull data from openshift spar database to object storage
* push data from object storage to containerized postgres databases

This is all to support a development environment for the sync process, and also to enable
support for debugging when trying to resolve issues that may come up with the process.

# Local Development

#### Init project

This is a run once per project, and had already been run for this project.  It inits a project
and allows for the definition of the requirements for the project, through an interactive prompting
system.

```
uv init
```

#### Create lock file
```
uv lock
```

#### Create the venv

* `uv lock` will do this for you or...
* `uv sync`

#### Run a script

`uv run python <path to script>`


# Run Local Spar Database

Describing the steps required to run the python code that will load the spar data
from object store to a local database.  These docs are mostly to support local
development of the injest scripts.  If just running the spar injest process run
the docker compose.

## Start Database

Need a local database to load the data to, so start the spar database by running

`docker compose up spar-db-migrations`

## Populate Env Var / Secrets

Different processes need different credentials.  See the env_sample as it breaks
up the credentials required for different processes.





