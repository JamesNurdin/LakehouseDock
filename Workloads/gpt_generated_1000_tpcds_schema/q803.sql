WITH
  ws_agg AS (
    SELECT
      ws_ship_mode_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      AVG(ws_quantity) AS avg_qty,
      COUNT(*) AS cnt_sales,
      MAX(ws_ext_sales_price) AS max_sales
    FROM web_sales
    WHERE CAST(ws_sales_price AS varchar) LIKE '%5%'
      AND regexp_like(CAST(ws_sales_price AS varchar), '^\\d+\\.5[0-9]$')
    GROUP BY ws_ship_mode_sk
  ),
  sm_processed AS (
    SELECT
      sm_ship_mode_sk,
      sm_ship_mode_id,
      sm_carrier,
      sm_code,
      sm_contract,
      regexp_extract(sm_contract, '(\\w{3})$', 1) AS contract_suffix,
      CASE
        WHEN sm_contract LIKE '%8%' THEN 'contains8'
        ELSE 'no8'
      END AS contract_flag,
      sm_carrier || '_' || sm_code AS carrier_code
    FROM ship_mode
  )
SELECT
  COALESCE(sm_processed.sm_ship_mode_id, CAST(ws_agg.ws_ship_mode_sk AS varchar)) AS ship_mode_key,
  sm_processed.carrier_code,
  sm_processed.contract_suffix,
  sm_processed.contract_flag,
  ws_agg.total_sales,
  ws_agg.avg_qty,
  CASE
    WHEN ws_agg.total_sales > 100000 THEN 'high'
    ELSE 'low'
  END AS sales_level,
  (
    SELECT COUNT(*)
    FROM web_sales ws2
    WHERE ws2.ws_ship_mode_sk = sm_processed.sm_ship_mode_sk
  ) AS total_orders_for_mode,
  l.contract_has_8_at_pos6
FROM sm_processed
FULL OUTER JOIN ws_agg
  ON sm_processed.sm_ship_mode_sk = ws_agg.ws_ship_mode_sk
CROSS JOIN LATERAL (
  SELECT regexp_like(sm_processed.sm_contract, '^.{5}8') AS contract_has_8_at_pos6
) l
WHERE sm_processed.contract_flag = 'contains8' OR ws_agg.total_sales IS NOT NULL
ORDER BY sales_level DESC, ws_agg.total_sales DESC
LIMIT 100
