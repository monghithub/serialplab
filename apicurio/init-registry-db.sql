-- Inicializa la base de datos para Apicurio Registry
-- Se ejecuta como parte del init de PostgreSQL

CREATE USER registry WITH PASSWORD 'registry';
CREATE DATABASE registry OWNER registry;
GRANT ALL PRIVILEGES ON DATABASE registry TO registry;