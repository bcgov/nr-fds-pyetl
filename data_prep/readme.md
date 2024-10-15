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

This is a run once per project, and had already been run for this project.  Its inits a project
and allows for the definition of the requirements for the project, through an interactive prompting 
system.

```
poetry init
```

#### Create lock file
```
poetry lock
```

#### Create the venv
```
poetry install --no-root
```

#### Run a script

poetry python <path to script>
