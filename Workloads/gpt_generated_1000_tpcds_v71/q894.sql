WITH prefix_cte AS (
  SELECT DISTINCT regexp_extract(i_product_name, '^([^ ]+)', 1) AS prod_prefix
  FROM item
),
store_sales_agg AS (
  SELECT
    d.d_year,
    s.s_store_name AS channel_name,
    p.prod_prefix,
    SUM(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN prefix_cte p ON regexp_extract(i.i_product_name, '^([^ ]+)', 1) = p.prod_prefix
  WHERE d.d_year = 2001
    AND regexp_like(i.i_product_name, '(?i)Premium')
    AND s.s_store_name LIKE '%Market%'
  GROUP BY d.d_year, s.s_store_name, p.prod_prefix
),
web_sales_agg AS (
  SELECT
    d.d_year,
    w.web_name AS channel_name,
    p.prod_prefix,
    SUM(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN prefix_cte p ON regexp_extract(i.i_product_name, '^([^ ]+)', 1) = p.prod_prefix
  WHERE d.d_year = 2001
    AND i.i_product_name LIKE '%Deluxe%'
    AND regexp_like(w.web_name, '(?i)Online')
  GROUP BY d.d_year, w.web_name, p.prod_prefix
)
SELECT *
FROM (
  SELECT d_year, channel_name, prod_prefix, total_net_paid
  FROM store_sales_agg
  UNION ALL
  SELECT d_year, channel_name, prod_prefix, total_net_paid
  FROM web_sales_agg
) combined
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
