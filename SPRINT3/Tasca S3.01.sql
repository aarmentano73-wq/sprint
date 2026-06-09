-- NIVEL 1:

--EJERCICIO 1: Arquitectura de Datos. Cración Dataset sprint3_silver:

CREATE SCHEMA `sprint3-analytics-albert.sprint3_silve`
OPTIONS (location = 'EU'
);

-- EJERCICIO 2: Ingesta en Capa Bronze (Conexión DDL): 

-- Create External Table TRANSACTIONS_RAW:

CREATE EXTERNAL TABLE `sprint3-analytics-albert.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

-- Create External Table COMPANIES_RAW:

CREATE EXTERNAL TABLE `sprint3-analytics-albert.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  address STRING,
  city STRING,
  country STRING,
  phone STRING,
  email STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- Create External Table AMERICAN_USERS_RAW:

CREATE EXTERNAL TABLE `sprint3-analytics-albert.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

-- Create External Table EUROPEAN_USERS_RAW: 

CREATE EXTERNAL TABLE `sprint3-analytics-albert.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

-- Create External Table CREDIT_CARDS_RAW:

CREATE EXTERNAL TABLE `sprint3-analytics-albert.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);

-- EJERCICIO 3: Carga de Datos Locales (Upload):

-- Creación Tabla Nativa PRODUCTS_RAW:

CREATE TABLE `sprint3-analytics-albert.sprint3_bronze.products_raw` (
  product_id INT64,
  product_name STRING,
  category STRING,
  price FLOAT64
);

-- EJERCICIO 4: Arquitectura y Rendimiento. Materialización de Datos (Asistido por IA)

-- Creación sprint3_bronze_transactions_raw_native SQL por IA: 

CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_bronze.transactions_raw_native`
AS
SELECT * FROM `sprint3-analytics-albert.sprint3_bronze.transactions_raw`

-- EJERCICIO 5: Adaptación de Sintaxis (Reporting):

-- 5 dias con mas ingresos en el año 2021:

SELECT
  DATE(timestamp) AS dia,
  SUM(amount) AS total_ingressos
FROM `sprint3-analytics-albert.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT (YEAR FROM timestamp) = 2021
GROUP BY dia
ORDER BY total_ingressos
LIMIT 5;

-- EJERCICIO 6: Consultas Complejas: 

SELECT 
    c.company_name, 
    c.country, 
    DATE(t.timestamp) AS data_transaccio
FROM  `sprint3-analytics-albert.sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3-analytics-albert.sprint3_bronze.companies_raw` AS c 
ON t.business_id = c.company_id
WHERE  t.amount BETWEEN 100 AND 200 AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY  data_transaccio;


-- NIVEL 2 LIMPIEZA Y TRANSFORMACIÓN (ELT) (CAPA SILVER):

-- EJERCICIO 1: LIMPIEZA de Productos (Data Quality)

CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  CAST(REPLACE(price, '$', '') AS FLOAT64) AS price,
  weight
FROM `sprint3-analytics-albert.sprint3_bronze.products_raw`;

-- EJERCICIO 2: Creación de Transacciones Limpias (Capa Silver)

CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
  timestamp,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude,
  ARRAY(
    SELECT CAST(TRIM(x) AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS x
  ) AS product_ids,
  card_id,
  business_id,
  declined,
  user_id
FROM `sprint3-analytics-albert.sprint3_bronze.transactions_raw`;

-- EJERCICIO 3: UNIFICACIÓN de Usuarios (UNION) y CAMBIO de nombre columna -id a -user_id:

CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'USA' AS origin
FROM `sprint3-analytics-albert.sprint3_bronze.american_users_raw`
UNION ALL
SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'EU' AS origin
FROM `sprint3-analytics-albert.sprint3_bronze.european_users_raw`;

-- EJERCICIO 4: Materialización de Compañias y Tarjetas de Crédito:

-- 4.1: Materialitzación de Compañias (Silver)


CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_silver.companies_clean` AS
SELECT
  company_id,
  company_name,
  phone,
  email,
  country,
  website
FROM `sprint3-analytics-albert.sprint3_bronze.companies_raw`;

-- 4.2: Materialitzación de Tarjetas de Crédito (Silver)

CREATE OR REPLACE TABLE `sprint3-analytics-albert.sprint3_silver.credit_cards_clean` AS
SELECT
  id AS credit_card_id,
  user_id,
  iban,
  pan,
  pin,
  cvv,
  track1,
  track2,
  expiring_date
FROM `sprint3-analytics-albert.sprint3_bronze.credit_cards_raw`;

-- NIVELL 3

-- EJERCICIO 1: CREACIÓN de una vista sprint3_gold.v_marketing_kpis

CREATE OR REPLACE VIEW `sprint3_gold.v_marketing_kpis` AS
SELECT
  c.company_name AS company_name,
  c.phone AS phone,
  c.country AS country,
  AVG(t.amount) AS avg_amount,
  CASE
    WHEN AVG(t.amount) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint3_silver.companies_clean` AS c
JOIN `sprint3_silver.transactions_clean` AS t
  ON c.company_id = t.business_id
GROUP BY
  c.company_name,
  c.phone,
  c.country;

-- Consulta SELECT * 

SELECT *
FROM `sprint3_gold.v_marketing_kpis`
ORDER BY
  CASE WHEN client_tier = 'Premium' THEN 1 ELSE 2 END,
  avg_amount DESC;

-- EJERCICIO 2: CREACIÓN tabla sprint3_gold.product_sales_ranking

CREATE OR REPLACE TABLE `sprint3_gold.product_sales_ranking` AS
WITH exploded AS (
SELECT
    t.transaction_id,
    product_id
FROM `sprint3_silver.transactions_clean` t,
  UNNEST(t.product_ids) AS product_id
)
SELECT
  p.product_id,
  p.name,
  p.price,
  COUNT(e.product_id) AS total_sold
FROM `sprint3_silver.products_clean` p
LEFT JOIN exploded e
  ON p.product_id = e.product_id
GROUP BY
  p.product_id,
  p.name,
  p.price
ORDER BY total_sold DESC;

