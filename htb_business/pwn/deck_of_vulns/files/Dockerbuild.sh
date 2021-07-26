#!/bin/sh

docker build -t deck_of_vulns .
docker run --name deck_of_vulns -p 1337:1337 -d deck_of_vulns