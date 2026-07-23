WITH pm_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_am_pm = 'PM'
)
SELECT sales_channel,
       warehouse_name,
       total_net_paid,
       total_net_profit
FROM (
    SELECT 'Catalog' AS sales_channel,
           w.w_warehouse_name AS warehouse_name,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN pm_time pt ON cs.cs_sold_time_sk = pt.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 0
    GROUP BY w.w_warehouse_name
    UNION ALL
    SELECT 'Web' AS sales_channel,
           w.w_warehouse_name AS warehouse_name,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN pm_time pt ON ws.ws_sold_time_sk = pt.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 0
    GROUP BY w.w_warehouse_name
) AS combined
ORDER BY sales_channel, total_net_paid DESC
