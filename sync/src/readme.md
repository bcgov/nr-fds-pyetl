# Test updates to sync script:

## Build image

`docker build -t sync .`

force rebuild everything
`docker build --no-cache -t sync .`

## Run image

`docker run --env-file=localenvs.txt sync:latest`

docker network ls

docker run --env-file=localenvs.txt --network=nr-fds-pyetl_default sync:latest

## Debug image

`docker run -it --entrypoint /bin/bash --env-file=localenvs.txt sync:latest`

