#!/bin/bash

docker run \
  --name wiretap \
  -p 9090:9090 \
  -p 9091:9091 \
  -p 9092:9092 \
  --rm \
  -v $PWD/api.openapi.json:/api.openapi.json:ro \
  -v $PWD/model.openapi.json:/model.openapi.json:ro \
 pb33f/wiretap -u https://spansh.co.uk -strict-mode -s /api.openapi.json
