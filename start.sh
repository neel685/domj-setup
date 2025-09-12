sudo ./config_user_and_grub.sh

sudo docker compose up -d mariadb domserver

sudo docker exec -it domserver cat /opt/domjudge/domserver/etc/restapi.secret

echo "Use this password and put it in the docker-compose.yaml and then execute sudo docker compose up -d to start all hosts or use script part two after changing password"
