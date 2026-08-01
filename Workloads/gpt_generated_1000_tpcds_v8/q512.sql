WITH
  sampled_catalog AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_returned_date_sk,
      r.r_reason_desc,
      sm.sm_code,
      w.w_warehouse_name
    FROM catalog_returns AS cr
    TABLESAMPLE BERNOULLI (10)
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 100
  ),
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_returned_date_sk,
      r.r_reason_desc,
      s.s_store_name
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt > 100
  ),
  order_diff AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  )
SELECT
  COALESCE(cat.key, sto.key) AS return_key,
  COALESCE(cat.amount, sto.amount) AS amount,
  COALESCE(cat.reason_desc, sto.reason_desc) AS reason_desc,
  COALESCE(cat.ship_mode, sto.ship_mode) AS ship_mode,
  COALESCE(cat.warehouse, sto.warehouse) AS warehouse,
  COALESCE(cat.source, sto.source) AS source
FROM (
  SELECT
    c.cr_order_number AS key,
    c.cr_return_amount AS amount,
    c.r_reason_desc AS reason_desc,
    c.sm_code AS ship_mode,
    c.w_warehouse_name AS warehouse,
    'catalog' AS source
  FROM sampled_catalog c
  WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = c.cr_returned_date_sk
      AND ws.ws_net_profit > 0
  )
  AND EXISTS (
    SELECT 1
    FROM order_diff od
    WHERE od.ws_order_number = c.cr_order_number
  )
) cat
FULL OUTER JOIN (
  SELECT
    s.sr_ticket_number AS key,
    s.sr_return_amt AS amount,
    s.r_reason_desc AS reason_desc,
    CAST(NULL AS varchar) AS ship_mode,
    CAST(NULL AS varchar) AS warehouse,
    'store' AS source
  FROM store_ret s
  WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = s.sr_returned_date_sk
      AND ws.ws_net_profit > 0
  )
) sto
ON cat.key = sto.key

UNION ALL

SELECT
  ws.ws_order_number AS return_key,
  ws.ws_net_paid AS amount,
  CAST(NULL AS varchar) AS reason_desc,
  sm.sm_code AS ship_mode,
  w.w_warehouse_name AS warehouse,
  'web_sales' AS source
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_net_paid > 0
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = ws.ws_order_number
  )

ORDER BY return_key ASC
OFFSET 0
LIMIT 100
