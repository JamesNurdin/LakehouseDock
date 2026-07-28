WITH store_sales_agg AS (
  SELECT
    ss.ss_store_sk,
    SUM(ss.ss_net_paid) AS total_store_sales,
    AVG(ss.ss_net_profit) AS avg_store_profit,
    COUNT(*) AS cnt_store_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND d.d_date = DATE '2001-01-15'
    AND t.t_hour BETWEEN 9 AND 17
    AND ss.ss_quantity > 5
  GROUP BY ss.ss_store_sk
),
web_sales_agg AS (
  SELECT
    ws.ws_sold_date_sk AS sold_date_sk,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    COUNT(*) AS cnt_web_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND d.d_date = DATE '2001-01-15'
    AND ws.ws_wholesale_cost > 50
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY ws.ws_sold_date_sk
),
combined AS (
  SELECT
    ssag.ss_store_sk AS store_sk,
    NULL AS date_sk,
    ssag.total_store_sales,
    ssag.avg_store_profit,
    ssag.cnt_store_sales,
    NULL AS total_web_sales,
    NULL AS avg_web_profit,
    NULL AS cnt_web_sales,
    'store' AS source
  FROM store_sales_agg ssag
  UNION ALL
  SELECT
    NULL,
    wsag.sold_date_sk,
    NULL,
    NULL,
    NULL,
    wsag.total_web_sales,
    wsag.avg_web_profit,
    wsag.cnt_web_sales,
    'web' AS source
  FROM web_sales_agg wsag
)
SELECT
  COALESCE(s.s_store_id, 'UNKNOWN') AS store_id,
  d.d_date_id,
  CASE WHEN c.source = 'store' THEN 'Store Sales' ELSE 'Web Sales' END AS sales_type,
  COALESCE(c.total_store_sales, c.total_web_sales) AS total_sales,
  COALESCE(c.avg_store_profit, c.avg_web_profit) AS avg_profit,
  COALESCE(c.cnt_store_sales, c.cnt_web_sales) AS transaction_count,
  CASE
    WHEN COALESCE(c.total_store_sales, c.total_web_sales) > 100000 THEN 'High'
    WHEN COALESCE(c.total_store_sales, c.total_web_sales) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_volume_category
FROM combined c
LEFT JOIN store s ON c.store_sk = s.s_store_sk
LEFT JOIN date_dim d ON c.date_sk = d.d_date_sk
WHERE (s.s_gmt_offset = -5.00 OR s.s_state = 'CA' OR d.d_moy = 5)
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_net_profit > 5000
      )
ORDER BY total_sales DESC
LIMIT 100
