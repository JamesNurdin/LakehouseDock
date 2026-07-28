-- goal: Compare warehouse-level profit performance across catalog and web channels for recent sales, categorizing profit levels and showing only profitable warehouses.
WITH catalog AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450815 AND 2451065
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name
    HAVING
        SUM(cs.cs_net_profit) > 0
),
web AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450815 AND 2451065
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name
    HAVING
        SUM(ws.ws_net_profit) > 0
)
SELECT
    combined.w_warehouse_id,
    combined.w_warehouse_name,
    combined.channel,
    combined.total_profit,
    combined.profit_category
FROM (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
) AS combined
ORDER BY
    combined.total_profit DESC
LIMIT 100
