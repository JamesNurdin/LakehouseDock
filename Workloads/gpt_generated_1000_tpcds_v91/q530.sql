WITH
  sm_processed AS (
    SELECT
      sm_ship_mode_sk,
      sm_ship_mode_id,
      sm_code,
      sm_carrier,
      regexp_extract(sm_carrier, '(\\w+)', 1) AS carrier_word,
      CONCAT(sm_code, '_', sm_carrier) AS mode_carrier_desc,
      SUBSTRING(sm_carrier FROM 1 FOR 3) AS carrier_prefix
    FROM ship_mode
    WHERE (sm_code LIKE 'A%' OR sm_code LIKE 'S%')
      AND regexp_like(sm_carrier, 'R')
  ),
  ws_processed AS (
    SELECT
      ws_order_number,
      ws_ship_mode_sk,
      ws_ext_tax,
      ws_net_profit,
      CONCAT('ORD', CAST(ws_order_number AS VARCHAR)) AS order_id_str,
      CAST(ws_ext_tax * 0.1 AS DECIMAL(7,2)) AS estimated_tax_rate,
      CAST(ws_net_profit AS DECIMAL(7,2)) AS profit_amount
    FROM web_sales
    WHERE ws_ext_tax > 50
  ),
  high_tax_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ext_tax > 1000
  ),
  low_tax_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_ext_tax <= 1000
  ),
  exclusive_high_tax_orders AS (
    SELECT ws_order_number
    FROM high_tax_orders
    EXCEPT
    SELECT ws_order_number
    FROM low_tax_orders
  )
SELECT
  sm.sm_ship_mode_id,
  sm.mode_carrier_desc,
  sm.carrier_prefix,
  sm.carrier_word,
  SUM(ws.profit_amount) AS total_profit,
  SUM(ws.ws_ext_tax) AS total_tax,
  COUNT(DISTINCT ws.ws_order_number) AS total_orders,
  COUNT(DISTINCT eo.ws_order_number) AS exclusive_high_tax_orders
FROM ws_processed ws
FULL OUTER JOIN sm_processed sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN exclusive_high_tax_orders eo
  ON ws.ws_order_number = eo.ws_order_number
GROUP BY
  sm.sm_ship_mode_id,
  sm.mode_carrier_desc,
  sm.carrier_prefix,
  sm.carrier_word
ORDER BY total_profit DESC
