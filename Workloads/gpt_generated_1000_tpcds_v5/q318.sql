WITH filtered_sales AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        td.t_sub_shift,
        wp.wp_type,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_sub_shift = 'morning'
      AND td.t_am_pm = 'AM'
      AND td.t_second = 9
      AND wp.wp_char_count > 2000
      AND wp.wp_type = 'article'
      AND ws.ws_net_paid_inc_ship_tax > 1000
)
SELECT
    t_sub_shift,
    wp_type,
    SUM(ws_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    AVG(ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    MIN(ws_net_profit) AS min_net_profit,
    MAX(ws_ext_discount_amt) AS max_ext_discount_amt,
    SUM(CASE WHEN ws_net_profit > 0 THEN 1 ELSE 0 END) AS positive_profit_orders
FROM filtered_sales
GROUP BY ROLLUP (t_sub_shift, wp_type)
ORDER BY total_net_paid_inc_ship_tax DESC
LIMIT 100
