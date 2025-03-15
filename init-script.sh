#!/bin/bash

# Instalar herramientas necesarias
echo "Instalando herramientas necesarias..."
apt-get update >> /tmp/log.txt 2>&1
apt-get install -y netcat curl postgresql-client >> /tmp/log.txt 2>&1

# Ejecutar Odoo en segundo plano
echo "Iniciando Odoo..."
/usr/bin/odoo -c /etc/odoo/.env --dev all -i web_enterprise >> /tmp/log.txt 2>&1 &

# Esperar a que Odoo esté completamente disponible
echo "Esperando a que Odoo esté disponible..."
until curl -s http://${WEB_HOST}:${WEB_PORT}/web/login | grep -q "Odoo"
do
  echo "Odoo no está disponible aún. Esperando..."
  sleep 5
done

echo "Odoo está disponible."

# Función para ejecutar comandos SQL con reintentos
execute_sql_with_retries() {
  local max_retries=5
  local retry_interval=10
  local attempt=1

  while [ $attempt -le $max_retries ]
  do
    echo "Intento $attempt de $max_retries para ejecutar comandos SQL en la base de datos..."

    export PGPASSWORD=${DB_PASSWD}
    if psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} -f /init-db.sql; then
      echo "Comandos SQL ejecutados con éxito."
      return 0
    else
      echo "Error al ejecutar comandos SQL. Intentando de nuevo en $retry_interval segundos..."
      sleep $retry_interval
      attempt=$((attempt + 1))
    fi
  done

  echo "Falló la ejecución de comandos SQL después de $max_retries intentos."
  return 1
}

# Ejecutar comandos SQL en la base de datos con reintentos
echo "Ejecutando comandos SQL en la base de datos..."
execute_sql_with_retries

sleep 5

# Detener Odoo
echo "Deteniendo Odoo..."
pkill -f 'odoo -c /etc/odoo/.env'

sleep 5

# Reiniciar Odoo
echo "Reiniciando Odoo..."
/usr/bin/odoo -c /etc/odoo/.env --dev all -i web_enterprise

