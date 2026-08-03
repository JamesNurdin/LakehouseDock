WITH base_agg AS (
   SELECT w.w_warehouse_name AS warehouse_name,
          t.t_hour,
          SUM(ws.ws_net_profit) AS sum_profit,
          COUNT(*) AS cnt_sales
   FROM web_sales ws
   FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE c.c_birth_month IN (1, 2, 3, 4, 5)
     AND c.c_preferred_cust_flag = 'Y'
     AND t.t_minute BETWEEN 0 AND 30
     AND t.t_sub_shift = 'morning'
     AND ws.ws_net_paid_inc_ship > 2000
   GROUP BY w.w_warehouse_name, t.t_hour
),
ship_agg AS (
   SELECT w.w_warehouse_name AS warehouse_name,
          t.t_hour,
          SUM(ws.ws_net_profit) AS sum_profit,
          COUNT(*) AS cnt_sales
   FROM web_sales ws
   FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN customer c
        ON ws.ws_ship_customer_sk = c.c_customer_sk
   WHERE c.c_birth_month IN (6, 7, 8, 9, 10)
     AND c.c_preferred_cust_flag = 'N'
     AND t.t_minute BETWEEN 30 AND 59
     AND t.t_sub_shift = 'afternoon'
     AND ws.ws_ext_list_price > 1000
   GROUP BY w.w_warehouse_name, t.t_hour
),
union_agg AS (
   SELECT warehouse_name, t_hour, sum_profit, cnt_sales FROM base_agg
   UNION DISTINCT
   SELECT warehouse_name, t_hour, sum_profit, cnt_sales FROM ship_agg
)
SELECT ua.warehouse_name,
       AVG(ua.sum_profit) AS avg_profit,
       SUM(ua.cnt_sales) AS total_sales
FROM union_agg ua
GROUP BY ua.warehouse_name
HAVING AVG(ua.sum_profit) > 5000
ORDER BY avg_profit DESC
LIMIT 100
