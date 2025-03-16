#!/bin/bash

# Ejecutar Odoo
echo "Iniciando Odoo..."
sleep 5
/usr/bin/odoo -c /etc/odoo/odoo.conf -i base -d ${DB_NAME} & 
ODOO_PID=$!

# Esperar a que Odoo esté completamente disponible
echo "Esperando a que Odoo esté disponible..."
until curl -s http://localhost:${WEB_PORT}/web/login | grep -q "Odoo"
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
    if psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} -f init-db.sql; then
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
if kill $ODOO_PID 2>/dev/null; then
    echo "Proceso Odoo (PID: $ODOO_PID) detenido"
else
    echo "No se pudo detener el proceso de Odoo"
fi

sleep 5

# Reiniciar Odoo
echo "Reiniciando Odoo..."
/usr/bin/odoo -c /etc/odoo/odoo.conf -i web_enterprise -d ${DB_NAME}
