WITH
  filtered_items AS (
    SELECT
      i_item_sk,
      i_product_name,
      i_item_desc,
      CASE
        WHEN regexp_like(i_item_desc, '^.*[0-9]{3}.*$') THEN 'Has3Digits'
        ELSE 'No3Digits'
      END AS desc_category
    FROM tpcds.item
    WHERE i_product_name LIKE 'A%'
  ),
  recent_years AS (
    SELECT d_year, d_month_seq
    FROM tpcds.date_dim
    WHERE d_year IN (2000, 2001)
  ),
  computed_set AS (
    SELECT 1 AS grp UNION ALL SELECT 2 AS grp
  ),
  sales_union AS (
    SELECT
      dy.d_year,
      dy.d_month_seq,
      fi.desc_category,
      cs.cs_net_paid AS net_paid,
      cs.cs_order_number AS order_number,
      cs.grp
    FROM tpcds.catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN tpcds.date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN recent_years dy ON dy.d_year = dd.d_year AND dy.d_month_seq = dd.d_month_seq
    CROSS JOIN computed_set cs
    WHERE regexp_like(fi.i_item_desc, '.*[A-Z]{2}.*')
  ),
  web_union AS (
    SELECT
      dy.d_year,
      dy.d_month_seq,
      fi.desc_category,
      ws.ws_net_paid AS net_paid,
      ws.ws_order_number AS order_number,
      ws.grp
    FROM tpcds.web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN tpcds.date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN recent_years dy ON dy.d_year = dd.d_year AND dy.d_month_seq = dd.d_month_seq
    CROSS JOIN computed_set ws
    WHERE regexp_like(fi.i_item_desc, '.*[A-Z]{2}.*')
  )
SELECT
  u.d_year,
  u.d_month_seq,
  u.desc_category,
  SUM(u.net_paid) AS total_net_paid,
  COUNT(DISTINCT u.order_number) AS unique_orders,
  u.grp
FROM (
  SELECT * FROM sales_union
  UNION DISTINCT
  SELECT * FROM web_union
) u
GROUP BY u.d_year, u.d_month_seq, u.desc_category, u.grp
ORDER BY total_net_paid DESC
LIMIT 100
