WITH
  ws_agg AS (
    SELECT
      i.i_item_id,
      i.i_color,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_quantity) AS total_qty,
      COUNT(*) AS txn_count,
      MAX(ws.ws_sold_date_sk) AS latest_sold_date_sk,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '^.*[Aa]dvanced.*$')
      AND i.i_color LIKE 'r%'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_item_id, i.i_color
    HAVING SUM(ws.ws_ext_sales_price) > 1000
  ),
  ss_agg AS (
    SELECT
      i.i_item_id,
      i.i_color,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty,
      COUNT(*) AS txn_count,
      MAX(ss.ss_sold_date_sk) AS latest_sold_date_sk,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '^.*[Aa]dvanced.*$')
      AND i.i_color LIKE 'r%'
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_item_id, i.i_color
    HAVING SUM(ss.ss_ext_sales_price) > 1000
  )
SELECT
  i_item_id,
  i_color,
  total_sales,
  total_qty,
  txn_count,
  latest_sold_date_sk,
  sales_rank,
  CASE WHEN total_sales > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
  concat(i_color, '-', cast(total_qty AS varchar)) AS color_qty_key
FROM ws_agg
UNION ALL
SELECT
  i_item_id,
  i_color,
  total_sales,
  total_qty,
  txn_count,
  latest_sold_date_sk,
  sales_rank,
  CASE WHEN total_sales > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
  concat(i_color, '-', cast(total_qty AS varchar)) AS color_qty_key
FROM ss_agg
ORDER BY total_sales DESC
LIMIT 100
