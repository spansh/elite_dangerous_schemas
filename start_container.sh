#!/bin/bash

docker run \
  --name elite_dangerous_schemas \
  --mount source=/home/spansh/work/elite_dangerous_schemas,target=/elite_dangerous_schemas,type=bind \
  --mount source=/home/spansh/,target=/home/spansh/,type=bind \
  --mount source=$SSH_AUTH_SOCK,target=/ssh-agent,type=bind \
  --env SSH_AUTH_SOCK=/ssh-agent \
  --volume /etc/passwd:/etc/passwd:ro \
  --volume /etc/shadow:/etc/shadow:ro \
  --volume /etc/group:/etc/group:ro \
  -it \
  --rm \
  --user=$(id -u):$(id -g) \
  --workdir /elite_dangerous_schemas \
  --entrypoint bash ember
