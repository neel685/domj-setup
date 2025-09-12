sudo docker compose up -d

echo "This is the admin password"

sudo docker exec -it domserver cat /opt/domjudge/domserver/etc/initial_admin_password.secret

