WITH sales_page_agg AS (
    SELECT
        wp.wp_type,
        wp.wp_url,
        SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MAX(ws.ws_net_profit) AS max_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_net_paid_inc_ship > 2500
        AND ws.ws_ext_tax >= 10
        AND ws.ws_quantity >= 2
        AND ws.ws_ship_mode_sk IN (1, 2, 3)
        AND wp.wp_autogen_flag = 'N'
        AND wp.wp_max_ad_count >= 2
    GROUP BY wp.wp_type, wp.wp_url
)
SELECT
    wp_type,
    wp_url,
    total_net_paid,
    avg_discount,
    order_cnt,
    max_profit,
    RANK() OVER (PARTITION BY wp_type ORDER BY total_net_paid DESC) AS type_rank
FROM sales_page_agg
ORDER BY total_net_paid DESC
LIMIT 100
