#!/bin/bash
set -e

DOMSERVER_CONTAINER="domserver"
COMPOSE_FILE="docker-compose.yaml"

echo "[+] Starting mariadb and domserver..."
sudo docker compose up -d mariadb domserver

echo "[+] Waiting for domserver to initialize..."
sleep 10

echo "[+] Finding restapi.secret inside domserver..."
SECRET_PATH=$(sudo docker exec "$DOMSERVER_CONTAINER" find /opt -name restapi.secret 2>/dev/null | head -n1)

if [ -z "$SECRET_PATH" ]; then
  echo "[-] Could not find restapi.secret in domserver!"
  exit 1
fi

echo "[+] Found restapi.secret at $SECRET_PATH"

JUDGE_PW=$(sudo docker exec "$DOMSERVER_CONTAINER" awk '{print $2}' "$SECRET_PATH")

if [ -z "$JUDGE_PW" ]; then
  echo "[-] Failed to read judgedaemon password!"
  exit 1
fi

echo "[+] Retrieved judgedaemon password."

echo "[+] Updating docker-compose.yaml with new judgedaemon password..."
for i in 0 1 2 3; do
  yq e -i ".services[\"judgehost-$i\"].environment[] |= sub(\"^JUDGEDAEMON_PASSWORD=.*\", \"JUDGEDAEMON_PASSWORD=$JUDGE_PW\")" "$COMPOSE_FILE"
done

echo "[+] Starting all services..."
sudo docker compose up -d
