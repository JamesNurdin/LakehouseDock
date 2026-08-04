WITH
  agg_catalog_sales AS (
    SELECT
      cs_item_sk,
      cs_order_number,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_ship_mode_sk,
      SUM(cs_ext_sales_price) AS total_sales_price,
      SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    WHERE cs_quantity > 10
      AND cs_ext_sales_price > 100
    GROUP BY cs_item_sk, cs_order_number, cs_sold_date_sk, cs_sold_time_sk, cs_ship_mode_sk
  ),
  agg_web_sales AS (
    SELECT
      ws_item_sk,
      ws_order_number,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_mode_sk,
      SUM(ws_ext_sales_price) AS total_sales_price,
      SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_quantity > 15
      AND ws_ext_sales_price > 150
    GROUP BY ws_item_sk, ws_order_number, ws_sold_date_sk, ws_sold_time_sk, ws_ship_mode_sk
  ),
  catalog_side AS (
    SELECT
      agg.cs_item_sk,
      agg.cs_order_number,
      agg.total_sales_price,
      agg.total_quantity,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d.d_year,
      t.t_hour,
      sm.sm_type
    FROM agg_catalog_sales agg
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = agg.cs_item_sk
     AND cr.cr_order_number = agg.cs_order_number
    LEFT JOIN date_dim d
      ON d.d_date_sk = agg.cs_sold_date_sk
    LEFT JOIN time_dim t
      ON t.t_time_sk = agg.cs_sold_time_sk
    LEFT JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = agg.cs_ship_mode_sk
    WHERE d.d_year = 2001
      AND t.t_am_pm = 'PM'
  ),
  web_side AS (
    SELECT
      agg.ws_item_sk,
      agg.ws_order_number,
      agg.total_sales_price AS total_ws_sales_price,
      agg.total_quantity AS total_ws_quantity,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      d.d_year,
      t.t_hour,
      sm.sm_type
    FROM agg_web_sales agg
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = agg.ws_item_sk
     AND wr.wr_order_number = agg.ws_order_number
    LEFT JOIN date_dim d
      ON d.d_date_sk = agg.ws_sold_date_sk
    LEFT JOIN time_dim t
      ON t.t_time_sk = agg.ws_sold_time_sk
    LEFT JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = agg.ws_ship_mode_sk
    WHERE d.d_year = 2001
      AND t.t_hour >= 12
  )
SELECT
  COALESCE(cs.sm_type, ws.sm_type) AS ship_mode_type,
  SUM(COALESCE(cs.total_sales_price, 0)) AS total_catalog_sales,
  SUM(COALESCE(ws.total_ws_sales_price, 0)) AS total_web_sales,
  SUM(COALESCE(cs.cr_return_amount, 0)) AS total_catalog_returns,
  SUM(COALESCE(ws.wr_return_amt, 0)) AS total_web_returns,
  AVG(COALESCE(cs.t_hour, ws.t_hour)) AS avg_hour
FROM catalog_side cs
FULL OUTER JOIN web_side ws
  ON cs.cs_item_sk = ws.ws_item_sk
 AND cs.cs_order_number = ws.ws_order_number
GROUP BY COALESCE(cs.sm_type, ws.sm_type)
HAVING SUM(COALESCE(cs.total_sales_price, 0) + COALESCE(ws.total_ws_sales_price, 0)) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
