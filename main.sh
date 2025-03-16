#!/bin/bash

# Path to the .env file
env_file=".env"

# Path to the odoo.conf file
odoo_conf_file="config/odoo.conf"

# Add [options] at the beginning of odoo.conf
echo "[options]" > "$odoo_conf_file"

# Read each line from the .env file, skipping empty lines
grep -v '^\s*$' "$env_file" | while IFS= read -r line; do
    # Convert the key to lowercase, format with spaces around '=', and append to odoo.conf
    formatted_line=$(echo "$line" | sed 's/=/ = /')
    echo "${formatted_line,,}" >> "$odoo_conf_file"
done

# Execute docker compose up --build
docker compose up --build