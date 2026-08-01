WITH
  sub1 AS (
    SELECT
      i.i_category AS category,
      sm.sm_type AS ship_mode,
      ws.ws_ext_sales_price AS sales_amount,
      COALESCE(wr.wr_return_amt, 0) AS return_amount,
      CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_class,
      (SELECT AVG(i2.i_current_price)
         FROM item i2
        WHERE i2.i_category = i.i_category) AS avg_category_price,
      c.c_customer_sk,
      ws.ws_order_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND EXISTS (SELECT 1 FROM web_returns r WHERE r.wr_returning_customer_sk = c.c_customer_sk)
  ),
  sub2 AS (
    SELECT
      i.i_category AS category,
      sm.sm_type AS ship_mode,
      ws.ws_ext_sales_price AS sales_amount,
      COALESCE(wr.wr_return_amt, 0) AS return_amount,
      CASE WHEN ws.ws_net_profit > 2000 THEN 'High' ELSE 'Low' END AS profit_class,
      (SELECT AVG(i2.i_current_price)
         FROM item i2
        WHERE i2.i_category = i.i_category) AS avg_category_price,
      c.c_customer_sk,
      ws.ws_order_number
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450200 AND 2450300
      AND EXISTS (SELECT 1 FROM web_returns r WHERE r.wr_returning_customer_sk = c.c_customer_sk)
  ),
  union_data AS (
    SELECT * FROM sub1
    UNION
    SELECT * FROM sub2
  ),
  expanded AS (
    SELECT
      ud.*, 
      channel
    FROM union_data ud
    CROSS JOIN UNNEST(ARRAY['Retail', 'Online']) AS t(channel)
  )
SELECT
  category,
  ship_mode,
  profit_class,
  SUM(sales_amount) AS total_sales,
  SUM(return_amount) AS total_returns,
  AVG(avg_category_price) AS avg_price,
  RANK() OVER (PARTITION BY category ORDER BY SUM(sales_amount) DESC) AS sales_rank
FROM expanded
GROUP BY GROUPING SETS (
  (category, ship_mode, profit_class),
  (category, profit_class),
  (category),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
