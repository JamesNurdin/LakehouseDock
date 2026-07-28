SELECT
    sales_year,
    warehouse_name,
    total_net_profit,
    total_quantity
FROM (
    SELECT
        d.d_year AS sales_year,
        w.w_warehouse_name AS warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_warehouse_name
    HAVING SUM(cs.cs_net_profit) > 10000

    UNION ALL

    SELECT
        d.d_year AS sales_year,
        w.w_warehouse_name AS warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_warehouse_name
    HAVING SUM(ws.ws_net_profit) > 10000
) AS combined
ORDER BY sales_year DESC, total_net_profit DESC
LIMIT 100
