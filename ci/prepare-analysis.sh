#!/bin/sh
set -eu

docker stop minikube
docker start sonarqube

for attempt in $(seq 1 100); do
    if curl --max-time 5 -fsS \
        http://localhost:9000/api/system/status \
        | python3 -c 'import json,sys; sys.exit(json.load(sys.stdin).get("status") != "UP")'
    then
        echo "SonarQube prêt."
        exit 0
    fi
    sleep 3
done

echo "SonarQube ne répond pas dans le délai prévu."
exit 1
