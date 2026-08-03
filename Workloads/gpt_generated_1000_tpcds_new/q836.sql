WITH cat_sales AS (
  SELECT
    cs_bill_customer_sk AS customer_sk,
    cs_ship_mode_sk,
    cs_order_number,
    cs_quantity,
    cs_sales_price,
    ARRAY[cs_quantity, cs_sales_price] AS qty_price_arr
  FROM catalog_sales
  WHERE cs_quantity > 1
),
expanded AS (
  SELECT
    cs.customer_sk,
    cs.cs_ship_mode_sk,
    cs.cs_order_number,
    v.value AS metric_value,
    v.v_pos
  FROM cat_sales cs
  CROSS JOIN UNNEST(cs.qty_price_arr) WITH ORDINALITY AS v(value, v_pos)
),
ship_modes AS (
  SELECT sm_ship_mode_sk, sm_ship_mode_id, sm_type
  FROM ship_mode
)
SELECT
  e.customer_sk,
  sm.sm_ship_mode_id,
  sm.sm_type,
  e.metric_value,
  e.v_pos
FROM expanded e
RIGHT OUTER JOIN ship_modes sm
  ON e.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE EXISTS (
  SELECT 1
  FROM store_returns sr
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'F' AND sr.sr_customer_sk = e.customer_sk
)
EXCEPT
SELECT
  ws.ws_bill_customer_sk AS customer_sk,
  sm2.sm_ship_mode_id,
  sm2.sm_type,
  CAST(NULL AS decimal(7,2)) AS metric_value,
  CAST(NULL AS bigint) AS v_pos
FROM web_sales ws
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
WHERE ws.ws_quantity > 0
ORDER BY customer_sk
LIMIT 100
