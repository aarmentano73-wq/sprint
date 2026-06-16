
-- NIVEL 1:
-- Ejercicio 1:

SELECT
  t.*,
  c.company_name,
  c.country
FROM
  `sprint3-analytics-albert.sprint3_silver.transactions_clean` AS t
JOIN
  `sprint3-analytics-albert.sprint3_silver.companies_clean` AS c
ON
  t.business_id = c.company_id
WHERE
  DATE(t.timestamp) = '2022-03-12'
  AND c.country = 'Germany';

  --Ejercicio 2: Creación de Datos Recientes (Mocking Data)

  CREATE OR REPLACE TABLE `sprint3_silver.transactions_recent` AS
SELECT
  *,
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(RAND() * 50 AS INT64) DAY) AS timestamp
FROM
  (
  SELECT * EXCEPT(timestamp)
  FROM `sprint3_silver.transactions_clean`
  );

  --Ejercicio 2: Creación de la Mesa Optimizada (Partitioning & Clustering)  

CREATE OR REPLACE TABLE `sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id
AS
SELECT *
FROM `sprint3_silver.transactions_recent`;

--Ejercicio 3: 
SELECT *
FROM `sprint3_siler.transactions_recent`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

SELECT *
FROM `sprint3_gold.fact_transactions_optimized`  
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

--Ejercicio 4: Smart Caching (Vistes Materialitzades)

-- Creación tabla materializada: 

CREATE MATERIALIZED VIEW `sprint3_gold.mv_daily_sales` AS
SELECT
  DATE(timestamp) AS sale_date,
  SUM(amount) AS total_sales
FROM `sprint3_gold.fact_transactions_optimized`
GROUP BY sale_date;

-- Consulta tabla materializada:

SELECT *
FROM `sprint3_gold.mv_daily_sales`
ORDER BY sale_date DESC;

--NIVEL 2: SQL Analítico Avanzado

--Ejercicio 1: Perfilado de Clientes VIP (Métricas Agregadas con CTEs)
              

  WITH VIP_Stats AS (
  SELECT
    user_id,
    SUM(amount) AS total_gastat,
    COUNT(*) AS num_compres,
    ROUND(AVG(amount), 2) AS tiquet_mig,
    MAX(amount) AS max_compra
  FROM`sprint3_gold.fact_transactions_optimized`
  GROUP BY user_id
  HAVING SUM(amount) > 500
)
SELECT
  v.user_id,
  CONCAT(u.name,'',u.surname) AS nom_complet,
  u.email,
  v.num_compres,
  v.tiquet_mig,
  v.max_compra,
  ROUND(v.total_gastat, 2) AS total_gastat
FROM VIP_Stats v
JOIN `sprint3_silver.users_combined` u
ON v.user_id = u.user_id
ORDER BY v.total_gastat DESC;

--Ejercicio 2: Análisis de Tendencias (Window Functions sobre Vistas) 

SELECT
  sale_date AS Fecha,
  total_sales AS Vendes_Avui,
  LAG(total_sales) OVER (ORDER BY sale_date) AS Vendes_Ahir,
  ROUND(SAFE_DIVIDE(total_sales - LAG(total_sales) OVER (ORDER BY sale_date),
  LAG(total_sales) OVER (ORDER BY sale_date)) * 100, 2) AS Diff_Percentual
FROM
  `sprint3_gold.mv_daily_sales`
ORDER BY
  sale_date;

-- Ejercicio 3: Totales Acumulados (Running Totales sobre Vistas) 

SELECT
  sale_date AS Data,
  ROUND(total_sales, 2) AS Ventes_del_Dia,
  ROUND(SUM(total_sales) OVER (PARTITION BY EXTRACT(YEAR FROM sale_date)
  ORDER BY sale_date
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS Ventes_Acumulades_YTD
FROM `sprint3_gold.mv_daily_sales`
ORDER BY sale_date;

--Ejercicio 4: Fidelización y Valor del Cliente (Filtrado Avanzado) 

WITH compres_ordenades AS (
  SELECT
    user_id,
    DATE(timestamp) AS data_compra,
    amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp) AS num_compra
  FROM `sprint3_gold.fact_transactions_optimized`
)
SELECT
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nom_complet,
  u.email,
  c.data_compra AS data_3a_compra,
  c.amount AS import_3a_compra,
  ROUND(AVG(c.amount) OVER (PARTITION BY c.user_id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS med_3_primeres
FROM compres_ordenades c
JOIN `sprint3_silver.users_combined` u
ON c.user_id = u.user_id
QUALIFY num_compra = 3
ORDER BY med_3_primeres DESC;

--NIVEL 3:

--Ejercicio 1: Desanidamiento y Allanamiento de Datos (Unnesting) 

CREATE OR REPLACE TABLE `sprint3_gold.dim_transactions_flat` AS
SELECT
  t.transaction_id,
  t.timestamp,
  t.amount AS total_ticket,
  product_id AS product_sku,
  p.name AS product_name,
  p.price AS product_price
FROM `sprint3_silver.transactions_clean` t
CROSS JOIN UNNEST(t.product_ids) AS product_id
LEFT JOIN `sprint3_silver.products_clean` p
ON product_id = p.product_id;

--Ejercicio 2: El Ranking de Ventas (Agregación Simple) 

SELECT
  product_name,
  COUNT(*) AS unidades_vendidas
FROM `sprint3_gold.dim_transactions_flat`
GROUP BY product_name
ORDER BY unidades_vendidas DESC
LIMIT 5;


--Ejercicio 3: Automatización del Pipeline y Visualización 

-- El código SQL de la UDF. 

CREATE OR REPLACE FUNCTION `sprint3_gold.calculate_tax`(amount FLOAT64)
RETURNS FLOAT64
AS (
  amount * 1.21
);

--El código SQL actualizado de la creación de la tabla.


CREATE OR REPLACE TABLE `sprint3_gold.dim_transactions_flat` AS
SELECT
  t.transaction_id,
  t.timestamp,
  t.amount AS total_ticket,
  product_id AS product_sku,
  p.name AS product_name,
  p.price AS product_unit_price,
  `sprint3_gold.calculate_tax`(p.price) AS product_price_tax_inc
FROM `sprint3_silver.transactions_clean` t
CROSS JOIN UNNEST(t.product_ids) AS product_id
LEFT JOIN `sprint3_silver.products_clean` p
ON product_id = p.product_id;
