WITH base AS (
  SELECT
    ws.ws_web_site_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_ext_wholesale_cost,
    i.i_brand,
    i.i_units,
    i.i_rec_start_date,
    s.web_state
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  WHERE ws.ws_wholesale_cost > 10
    AND i.i_units IN ('Cup', 'Lb')
    AND s.web_state = 'OH'
    AND i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
),
agg AS (
  SELECT
    ws_web_site_sk,
    i_brand,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_wholesale_cost) AS total_wholesale,
    COUNT(*) AS txn_cnt
  FROM base
  GROUP BY GROUPING SETS (
    (ws_web_site_sk, i_brand),
    (ws_web_site_sk),
    (i_brand),
    ()
  )
),
filtered AS (
  SELECT
    ws_web_site_sk,
    i_brand,
    total_sales,
    total_wholesale,
    txn_cnt,
    total_sales - total_wholesale AS profit
  FROM agg
  WHERE total_sales > 1000
    AND total_wholesale > 500
    AND txn_cnt >= 5
)
SELECT DISTINCT
  COALESCE(CAST(ws_web_site_sk AS VARCHAR), 'ALL_SITES') AS site_key,
  COALESCE(i_brand, 'ALL_BRANDS') AS brand_key,
  profit,
  txn_cnt
FROM filtered
ORDER BY profit DESC
LIMIT 100
