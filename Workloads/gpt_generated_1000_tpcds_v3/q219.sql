SELECT *
FROM (
    SELECT w.w_warehouse_name AS warehouse_name,
           td.t_hour AS hour_of_day,
           SUM(cs.cs_net_paid) AS total_net_paid,
           AVG(cs.cs_net_profit) AS avg_net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_last_review_date > 2452400
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
            AND cr.cr_return_amount > 0
      )
    GROUP BY w.w_warehouse_name, td.t_hour

    UNION ALL

    SELECT w.w_warehouse_name AS warehouse_name,
           td.t_hour AS hour_of_day,
           SUM(ws.ws_net_paid) AS total_net_paid,
           AVG(ws.ws_net_profit) AS avg_net_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_last_review_date > 2452400
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
            AND cr.cr_return_amount > 0
      )
    GROUP BY w.w_warehouse_name, td.t_hour
) AS combined_sales
ORDER BY warehouse_name, hour_of_day, channel
LIMIT 100
