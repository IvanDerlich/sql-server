#!/bin/bash

docker compose down -v
docker compose up -d
docker compose --profile init run --rm db-init