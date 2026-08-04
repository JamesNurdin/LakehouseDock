WITH
  high_loss_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_net_loss > (
            SELECT avg(cr2.cr_net_loss)
            FROM catalog_returns cr2
          )
      AND t.t_am_pm = 'PM'
  ),
  low_profit_sales AS (
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE ws.ws_net_profit < 0
      AND t2.t_hour >= 12
  ),
  returned_orders AS (
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
    JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
    WHERE t3.t_am_pm = 'AM'
  )
SELECT order_number
FROM (
       SELECT order_number FROM high_loss_orders
       INTERSECT
       SELECT order_number FROM low_profit_sales
     ) AS intersect_set
EXCEPT
SELECT order_number FROM returned_orders
ORDER BY order_number
LIMIT 100
