WITH
store_sales_agg AS (
  SELECT
    d.d_year AS sales_year,
    s.s_country AS country,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_quantity) AS quantity_sold
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, s.s_country, i.i_item_id, i.i_product_name
),
store_returns_agg AS (
  SELECT
    d.d_year AS return_year,
    s.s_country AS country,
    i.i_item_id AS item_id,
    SUM(sr.sr_return_quantity) AS return_quantity,
    SUM(sr.sr_net_loss) AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, s.s_country, i.i_item_id
),
store_combined AS (
  SELECT
    ss.sales_year AS year,
    ss.country,
    ss.item_id,
    ss.product_name,
    ss.net_profit - COALESCE(sr.net_loss, 0) AS total_profit,
    ss.quantity_sold,
    COALESCE(sr.return_quantity, 0) AS return_quantity,
    'store' AS channel
  FROM store_sales_agg ss
  LEFT JOIN store_returns_agg sr
    ON ss.sales_year = sr.return_year
   AND ss.country = sr.country
   AND ss.item_id = sr.item_id
),
catalog_sales_agg AS (
  SELECT
    d.d_year AS sales_year,
    'N/A' AS country,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_quantity) AS quantity_sold
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id, i.i_product_name
),
catalog_returns_agg AS (
  SELECT
    d.d_year AS return_year,
    'N/A' AS country,
    i.i_item_id AS item_id,
    SUM(cr.cr_return_quantity) AS return_quantity,
    SUM(cr.cr_net_loss) AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id
),
catalog_combined AS (
  SELECT
    cs.sales_year AS year,
    cs.country,
    cs.item_id,
    cs.product_name,
    cs.net_profit - COALESCE(cr.net_loss, 0) AS total_profit,
    cs.quantity_sold,
    COALESCE(cr.return_quantity, 0) AS return_quantity,
    'catalog' AS channel
  FROM catalog_sales_agg cs
  LEFT JOIN catalog_returns_agg cr
    ON cs.sales_year = cr.return_year
   AND cs.item_id = cr.item_id
),
web_sales_agg AS (
  SELECT
    d.d_year AS sales_year,
    ws_site.web_country AS country,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_quantity) AS quantity_sold
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, ws_site.web_country, i.i_item_id, i.i_product_name
),
web_returns_agg AS (
  SELECT
    d.d_year AS return_year,
    'N/A' AS country,
    i.i_item_id AS item_id,
    SUM(wr.wr_return_quantity) AS return_quantity,
    SUM(wr.wr_net_loss) AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id
),
web_combined AS (
  SELECT
    ws.sales_year AS year,
    ws.country,
    ws.item_id,
    ws.product_name,
    ws.net_profit - COALESCE(wr.net_loss, 0) AS total_profit,
    ws.quantity_sold,
    COALESCE(wr.return_quantity, 0) AS return_quantity,
    'web' AS channel
  FROM web_sales_agg ws
  LEFT JOIN web_returns_agg wr
    ON ws.sales_year = wr.return_year
   AND ws.item_id = wr.item_id
),
combined AS (
  SELECT * FROM store_combined
  UNION ALL
  SELECT * FROM catalog_combined
  UNION ALL
  SELECT * FROM web_combined
),
ranked AS (
  SELECT
    year,
    channel,
    country,
    item_id,
    product_name,
    total_profit,
    quantity_sold,
    return_quantity,
    CASE WHEN quantity_sold = 0 THEN 0.0 ELSE CAST(return_quantity AS double) / quantity_sold END AS return_rate,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_profit DESC) AS rn
  FROM combined
)
SELECT
  year,
  channel,
  country,
  item_id,
  product_name,
  total_profit,
  quantity_sold,
  return_quantity,
  return_rate
FROM ranked
WHERE rn <= 10
ORDER BY year, rn
