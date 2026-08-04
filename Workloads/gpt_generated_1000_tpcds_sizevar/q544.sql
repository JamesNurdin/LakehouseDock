WITH
  sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  max_profit AS (
    SELECT max(ws_net_profit) AS max_np FROM web_sales
  ),
  sales_by_site AS (
    SELECT
      ws.ws_web_site_sk AS web_site_sk,
      web_site.web_name,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE
        WHEN SUM(ws.ws_net_profit) = (SELECT max_np FROM max_profit) THEN 'Top'
        ELSE 'Other'
      END AS profit_category,
      COALESCE(item_qty.total_quantity, 0) AS total_quantity
    FROM sampled_sales ws
    RIGHT OUTER JOIN web_site
      ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN LATERAL (
      SELECT SUM(ws2.ws_quantity) AS total_quantity
      FROM web_sales ws2
      WHERE ws2.ws_item_sk = ws.ws_item_sk
    ) AS item_qty ON TRUE
    LEFT JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020 OR d.d_year IS NULL
    GROUP BY ws.ws_web_site_sk, web_site.web_name, item_qty.total_quantity
  ),
  air_shipped_sites AS (
    SELECT DISTINCT
      web_site.web_site_sk,
      web_site.web_name
    FROM web_sales ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site
      ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE sm.sm_code = 'AIR' AND d.d_year = 2021
  )
SELECT *
FROM (
  SELECT web_site_sk, web_name, total_profit, profit_category, total_quantity
  FROM sales_by_site
) 
EXCEPT
SELECT web_site_sk, web_name, total_profit, profit_category, total_quantity
FROM (
  SELECT a.web_site_sk,
         a.web_name,
         0 AS total_profit,
         '' AS profit_category,
         0 AS total_quantity
  FROM air_shipped_sites a
) 
ORDER BY total_profit DESC NULLS LAST
