WITH web_agg AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  GROUP BY i.i_item_id, i.i_product_name
),
store_agg AS (
  SELECT
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  GROUP BY i.i_item_id, i.i_product_name
),
combined AS (
  SELECT item_id, product_name, total_sales, channel FROM web_agg
  UNION ALL
  SELECT item_id, product_name, total_sales, channel FROM store_agg
)
SELECT
  item_id,
  product_name,
  channel,
  total_sales,
  CASE WHEN total_sales >= 50000 THEN 'High' ELSE 'Medium' END AS sales_category,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS channel_rank,
  SUM(total_sales) OVER (PARTITION BY channel) AS channel_total_sales
FROM combined
ORDER BY total_sales DESC
LIMIT 100
