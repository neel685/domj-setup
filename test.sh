#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="docker-compose.yaml"
DOMSERVER_CONTAINER="domserver"
WAIT_SECONDS=2
MAX_WAIT=120

echo "[+] Starting mariadb and domserver..."
sudo docker compose up -d mariadb domserver

echo "[+] Waiting for domserver to initialize..."
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
  if sudo docker exec "$DOMSERVER_CONTAINER" test -f /opt/domjudge/domserver/etc/restapi.secret; then
    break
  fi
  sleep $WAIT_SECONDS
  elapsed=$((elapsed + WAIT_SECONDS))
done

if [ $elapsed -ge $MAX_WAIT ]; then
  echo "[-] Timeout: restapi.secret not found in domserver after $MAX_WAIT seconds."
  exit 1
fi

# Extract judgehost password (ignore comments, take 4th field)
JUDGEHOST_PASSWORD=$(sudo docker exec "$DOMSERVER_CONTAINER" bash -c "grep -v '^#' /opt/domjudge/domserver/etc/restapi.secret | awk '{print \$4}'")

# Extract admin password
ADMIN_PASSWORD=$(sudo docker exec "$DOMSERVER_CONTAINER" cat /opt/domjudge/domserver/etc/initial_admin_password.secret)

echo
echo "========================================"
echo " Judgehost password: $JUDGEHOST_PASSWORD"
echo " Admin password    : $ADMIN_PASSWORD"
echo "========================================"
echo

# Update all judgehost-* services in the YAML using sed (array-style)
echo "[+] Updating docker-compose.yaml..."
for svc in $(sudo docker compose config --services | grep judgehost); do
    sudo sed -i "s|JUDGEDAEMON_PASSWORD=.*|JUDGEDAEMON_PASSWORD=$JUDGEHOST_PASSWORD|" "$COMPOSE_FILE"
done

# Restart judgehosts
echo "[+] Restarting all judgehosts..."
sudo docker compose up -d $(sudo docker compose config --services | grep judgehost)

# Reset YAML permissions so user can edit normally
sudo chown $(whoami):$(whoami) "$COMPOSE_FILE"

echo "[+] Setup complete."
echo "------------------------------------------------"
echo " Judgehost password : $JUDGEHOST_PASSWORD"
echo " Admin password     : $ADMIN_PASSWORD"
echo "------------------------------------------------"
