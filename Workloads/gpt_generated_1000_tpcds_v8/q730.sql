WITH
  inventory_sample AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE inv_quantity_on_hand > 0
  ),
  store_sales_agg AS (
    SELECT
      COALESCE(s.s_store_id, 'UNKNOWN') AS entity_key,
      SUM(ss.ss_net_paid) AS total_amount,
      DATE_TRUNC('year', d.d_date) AS sales_year,
      'store' AS source,
      ROW_NUMBER() OVER (PARTITION BY COALESCE(s.s_store_id, 'UNKNOWN') ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
    FROM store_sales ss
    FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY COALESCE(s.s_store_id, 'UNKNOWN'), DATE_TRUNC('year', d.d_date)
  ),
  web_sales_agg AS (
    SELECT
      w.web_site_id AS entity_key,
      SUM(ws.ws_net_paid) AS total_amount,
      DATE_TRUNC('year', d.d_date) AS sales_year,
      'web' AS source,
      ROW_NUMBER() OVER (PARTITION BY w.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
    GROUP BY w.web_site_id, DATE_TRUNC('year', d.d_date)
  ),
  inventory_agg AS (
    SELECT
      CAST('INVENTORY' AS varchar) AS entity_key,
      SUM(inv.inv_quantity_on_hand) AS total_amount,
      DATE_TRUNC('year', d.d_date) AS sales_year,
      'inventory' AS source,
      ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rn
    FROM inventory_sample inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY DATE_TRUNC('year', d.d_date)
  )
SELECT *
FROM (
  SELECT entity_key, total_amount, sales_year, source, rn
  FROM store_sales_agg
  UNION
  SELECT entity_key, total_amount, sales_year, source, rn
  FROM web_sales_agg
  UNION
  SELECT entity_key, total_amount, sales_year, source, rn
  FROM inventory_agg
) u
ORDER BY total_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
