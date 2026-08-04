WITH store_agg AS (
    SELECT
        d.d_date AS sale_date,
        s.s_store_name AS entity_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_date, s.s_store_name
),
web_agg AS (
    SELECT
        d.d_date AS sale_date,
        w.w_warehouse_name AS entity_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_date, w.w_warehouse_name
)
SELECT sale_date, entity_name, total_sales, profit_category
FROM store_agg
UNION ALL
SELECT sale_date, entity_name, total_sales, profit_category
FROM web_agg
ORDER BY sale_date, entity_name
LIMIT 100
