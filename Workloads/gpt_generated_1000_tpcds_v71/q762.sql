WITH sales_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid,
        web_site.web_name,
        web_site.web_state,
        wp.wp_char_count
    FROM inventory inv
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE w.w_country = 'United States'
      AND wp.wp_char_count > 3000
      AND ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
      AND ws.ws_quantity >= 2
      AND web_site.web_state = 'CA'
),
agg AS (
    SELECT
        w_warehouse_id,
        web_name,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_qty,
        AVG(ws_net_paid) AS avg_paid
    FROM sales_data
    GROUP BY ROLLUP (w_warehouse_id, web_name)
)
SELECT
    COALESCE(w_warehouse_id, 'ALL_WAREHOUSES') AS warehouse_id,
    COALESCE(web_name, 'ALL_SITES') AS site_name,
    total_sales,
    total_profit,
    total_qty,
    avg_paid,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC NULLS LAST
