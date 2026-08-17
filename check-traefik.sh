#!/bin/bash
if docker ps --format '{{.Names}}' | grep -q "traefik"; then
    echo "OK" > /run/traefik-status.log
    exit 0
else
    echo "FAILED" > /run/traefik-status.log
    exit 1
fi

