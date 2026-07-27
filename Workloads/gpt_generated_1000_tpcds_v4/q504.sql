WITH store_sales_agg AS (
    SELECT
        td.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 10000 THEN 'Big' ELSE 'Small' END AS profit_group
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_minute BETWEEN 0 AND 30
    GROUP BY td.t_hour
),
web_sales_agg AS (
    SELECT
        td.t_hour AS hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'Big' ELSE 'Small' END AS profit_group
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States' AND td.t_minute BETWEEN 0 AND 30
    GROUP BY td.t_hour
)
SELECT hour, total_net_paid, profit_group
FROM store_sales_agg
UNION ALL
SELECT hour, total_net_paid, profit_group
FROM web_sales_agg
ORDER BY hour ASC, total_net_paid DESC
LIMIT 100
