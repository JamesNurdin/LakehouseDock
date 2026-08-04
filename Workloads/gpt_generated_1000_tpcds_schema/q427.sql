WITH
  sales_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  returns_orders AS (
    SELECT wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  orders_without_returns AS (
    SELECT ws_order_number
    FROM sales_orders
    EXCEPT
    SELECT wr_order_number
    FROM returns_orders
  ),
  orders_with_returns AS (
    SELECT ws_order_number
    FROM sales_orders
    INTERSECT
    SELECT wr_order_number
    FROM returns_orders
  ),
  base AS (
    SELECT
      ws.ws_order_number AS order_number,
      ws.ws_ext_tax,
      ws.ws_net_paid,
      ss.ss_quantity,
      ss.ss_ext_list_price,
      ss.ss_ext_wholesale_cost,
      wr.wr_net_loss,
      cc.cc_name,
      sm.sm_code,
      d_sales.d_year AS sales_year,
      d_sales.d_date_sk AS sales_date_sk
    FROM web_sales ws
    JOIN store_sales ss ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE d_sales.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND cc.cc_state = 'CA'
      AND ss.ss_quantity BETWEEN 1 AND 5
      AND ws.ws_ext_tax > 20
      AND (wr.wr_account_credit IS NULL OR wr.wr_account_credit < 50)
      AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_net_loss > 0
      )
      AND ws.ws_order_number IN (SELECT ws_order_number FROM orders_without_returns)
  )
SELECT
  cc_name,
  sm_code,
  sales_year,
  COUNT(DISTINCT order_number) AS order_cnt,
  SUM(ws_net_paid) AS total_net_paid,
  AVG(ss_ext_list_price) AS avg_store_list_price,
  MIN(ss_quantity) AS min_quantity,
  MAX(ws_ext_tax) AS max_tax,
  SUM(wr_net_loss) AS total_return_loss,
  (
    SELECT AVG(ws2.ws_ext_discount_amt)
    FROM web_sales ws2
    JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = base.sales_year
  ) AS avg_discount_on_day
FROM base
GROUP BY
  cc_name,
  sm_code,
  sales_year
ORDER BY total_net_paid DESC
OFFSET 20 LIMIT 100
