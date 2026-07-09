WITH page_sales AS (
    SELECT
        wp.wp_type,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_net_profit > 0
      AND wp.wp_type IN ('article', 'home', 'product')
    GROUP BY wp.wp_type, ws.ws_ship_mode_sk
),
type_totals AS (
    SELECT
        wp_type,
        SUM(total_sales) AS type_sales,
        SUM(total_profit) AS type_profit,
        SUM(order_cnt) AS type_orders
    FROM page_sales
    GROUP BY wp_type
)
SELECT
    ps.wp_type,
    ps.ws_ship_mode_sk,
    ps.total_sales,
    ps.total_profit,
    ps.order_cnt,
    ps.avg_discount,
    tt.type_sales,
    ROUND(ps.total_sales / tt.type_sales * 100, 2) AS sales_pct_of_type,
    RANK() OVER (PARTITION BY ps.wp_type ORDER BY ps.total_sales DESC) AS sales_rank
FROM page_sales ps
JOIN type_totals tt
    ON ps.wp_type = tt.wp_type
WHERE ps.total_sales > 10000
ORDER BY ps.wp_type, sales_rank
LIMIT 100
