WITH combined_sales AS (
    SELECT
        s.s_store_name AS store_name,
        w.w_warehouse_name AS warehouse_name,
        web_site.web_name AS web_site_name,
        d_cs.d_year AS year,
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        ws.ws_order_number,
        ws.ws_net_profit AS web_net_profit,
        (cs.cs_net_profit + ws.ws_net_profit) AS total_net_profit,
        cs.cs_quantity,
        ws.ws_quantity
    FROM catalog_sales cs
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN date_dim d_ws_open
        ON web_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ws_open.d_date_sk
    WHERE cs.cs_quantity > 1
      AND ws.ws_quantity > 1
      AND d_cs.d_year = 2001
      AND d_ws.d_year = 2001
      AND w.w_zip = '44593'
      AND web_site.web_tax_percentage > 0.05
      AND s.s_manager IN ('Jamal Henderson', 'Robert Thompson')
)
SELECT
    store_name,
    warehouse_name,
    web_site_name,
    year,
    SUM(total_net_profit) AS total_profit,
    AVG(total_net_profit) AS avg_profit,
    COUNT(*) AS transaction_count,
    SUM(total_net_profit) / (SELECT AVG(total_net_profit) FROM combined_sales) AS profit_ratio_to_overall_avg
FROM combined_sales
GROUP BY store_name, warehouse_name, web_site_name, year
HAVING SUM(total_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
