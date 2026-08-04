WITH
  sales_data AS (
    SELECT
      cs.cs_order_number AS order_number,
      i.i_brand,
      cs.cs_net_paid,
      cs.cs_sold_date_sk AS sold_date_sk,
      (SELECT SUM(cr.cr_return_amount)
         FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number) AS total_returns
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_manufact_id = (SELECT MAX(i_manufact_id) FROM item)
  ),
  web_data AS (
    SELECT
      ws.ws_order_number AS order_number,
      i.i_brand,
      ws.ws_net_paid,
      ws.ws_sold_date_sk AS sold_date_sk,
      (SELECT SUM(wr.wr_return_amt)
         FROM web_returns wr
         WHERE wr.wr_order_number = ws.ws_order_number) AS total_web_returns
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category = 'Electronics'
  ),
  full_joined AS (
    SELECT
      COALESCE(s.order_number, w.order_number) AS order_number,
      s.i_brand AS sales_brand,
      w.i_brand AS web_brand,
      s.cs_net_paid,
      w.ws_net_paid,
      s.total_returns,
      w.total_web_returns,
      LAG(s.cs_net_paid) OVER (PARTITION BY s.i_brand ORDER BY s.sold_date_sk) AS sales_lag_net_paid,
      LAG(w.ws_net_paid) OVER (PARTITION BY w.i_brand ORDER BY w.sold_date_sk) AS web_lag_net_paid
    FROM sales_data s
    FULL OUTER JOIN web_data w
      ON s.order_number = w.order_number
  ),
  catalog_orders AS (
    SELECT cs_order_number AS order_number FROM catalog_sales
  ),
  web_orders AS (
    SELECT ws_order_number AS order_number FROM web_sales
  ),
  orders_excluded AS (
    SELECT order_number FROM catalog_orders
    EXCEPT
    SELECT order_number FROM web_orders
  )
SELECT *
FROM (
  SELECT
    fj.order_number,
    fj.sales_brand,
    fj.web_brand,
    fj.cs_net_paid,
    fj.ws_net_paid,
    fj.total_returns,
    fj.total_web_returns,
    fj.sales_lag_net_paid,
    fj.web_lag_net_paid
  FROM full_joined fj

  UNION ALL

  SELECT
    oe.order_number,
    NULL AS sales_brand,
    NULL AS web_brand,
    NULL AS cs_net_paid,
    NULL AS ws_net_paid,
    NULL AS total_returns,
    NULL AS total_web_returns,
    NULL AS sales_lag_net_paid,
    NULL AS web_lag_net_paid
  FROM orders_excluded oe
) AS final_result
ORDER BY order_number
LIMIT 100
