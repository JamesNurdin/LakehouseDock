/*
  Monthly net contribution by item category across store, catalog, and web channels.
  Includes sales net profit, returns net loss, quantities sold and returned for the year 2001.
*/
WITH
  store_sales_data AS (
    SELECT
      ds.d_year,
      month(ds.d_date) AS month,
      i.i_category,
      ss.ss_quantity AS quantity_sold,
      ss.ss_net_profit AS net_profit,
      0.0 AS net_loss,
      0 AS quantity_returned,
      'store' AS channel
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  ),
  store_returns_data AS (
    SELECT
      dr.d_year,
      month(dr.d_date) AS month,
      i.i_category,
      0 AS quantity_sold,
      0.0 AS net_profit,
      sr.sr_net_loss AS net_loss,
      sr.sr_return_quantity AS quantity_returned,
      'store' AS channel
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  ),
  catalog_sales_data AS (
    SELECT
      ds.d_year,
      month(ds.d_date) AS month,
      i.i_category,
      cs.cs_quantity AS quantity_sold,
      cs.cs_net_profit AS net_profit,
      0.0 AS net_loss,
      0 AS quantity_returned,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  ),
  catalog_returns_data AS (
    SELECT
      dr.d_year,
      month(dr.d_date) AS month,
      i.i_category,
      0 AS quantity_sold,
      0.0 AS net_profit,
      cr.cr_net_loss AS net_loss,
      cr.cr_return_quantity AS quantity_returned,
      'catalog' AS channel
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  ),
  web_sales_data AS (
    SELECT
      ds.d_year,
      month(ds.d_date) AS month,
      i.i_category,
      ws.ws_quantity AS quantity_sold,
      ws.ws_net_profit AS net_profit,
      0.0 AS net_loss,
      0 AS quantity_returned,
      'web' AS channel
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  ),
  web_returns_data AS (
    SELECT
      dr.d_year,
      month(dr.d_date) AS month,
      i.i_category,
      0 AS quantity_sold,
      0.0 AS net_profit,
      wr.wr_net_loss AS net_loss,
      wr.wr_return_quantity AS quantity_returned,
      'web' AS channel
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  )
SELECT
  d_year,
  month,
  i_category,
  SUM(quantity_sold) AS total_quantity_sold,
  SUM(quantity_returned) AS total_quantity_returned,
  SUM(net_profit) AS total_net_profit,
  SUM(net_loss) AS total_net_loss,
  SUM(net_profit) - SUM(net_loss) AS net_contribution,
  SUM(quantity_sold) - SUM(quantity_returned) AS net_quantity
FROM (
  SELECT * FROM store_sales_data
  UNION ALL
  SELECT * FROM store_returns_data
  UNION ALL
  SELECT * FROM catalog_sales_data
  UNION ALL
  SELECT * FROM catalog_returns_data
  UNION ALL
  SELECT * FROM web_sales_data
  UNION ALL
  SELECT * FROM web_returns_data
) AS unified
GROUP BY d_year, month, i_category
ORDER BY d_year, month, i_category
