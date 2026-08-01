WITH store_aggregates AS (
  SELECT
    s.s_store_id AS location_id,
    s.s_store_name AS location_name,
    COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
    'store' AS source
  FROM store_sales ss
  RIGHT OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND i2.i_brand = 'BrandX'
  )
  GROUP BY s.s_store_id, s.s_store_name
  HAVING COALESCE(SUM(ss.ss_net_paid), 0) > 1000
     AND SUM(ss.ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales)
),
web_aggregates AS (
  SELECT
    wsit.web_site_id AS location_id,
    wsit.web_name AS location_name,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
    'web' AS source
  FROM web_sales ws
  RIGHT OUTER JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  LEFT JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  GROUP BY wsit.web_site_id, wsit.web_name
  HAVING COALESCE(SUM(ws.ws_net_paid), 0) > 1000
)
SELECT
  location_id,
  location_name,
  total_sales,
  total_profit,
  source
FROM store_aggregates
UNION ALL
SELECT
  location_id,
  location_name,
  total_sales,
  total_profit,
  source
FROM web_aggregates
LIMIT 100
