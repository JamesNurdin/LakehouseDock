WITH base_sales AS (
    SELECT
        td.t_sub_shift,
        wp.wp_type,
        ws.ws_sales_price,
        ws.ws_net_profit,
        wp.wp_web_page_id,
        wp.wp_link_count,
        wp.wp_customer_sk
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_sub_shift IN ('morning', 'afternoon')
      AND wp.wp_type IN ('order', 'welcome')
)
SELECT
    result.t_sub_shift,
    result.wp_type,
    result.price_category,
    COUNT(DISTINCT result.wp_web_page_id) AS distinct_pages,
    SUM(result.ws_net_profit) AS total_profit
FROM (
    SELECT
        b.t_sub_shift,
        b.wp_type,
        'high' AS price_category,
        b.ws_sales_price,
        b.ws_net_profit,
        b.wp_web_page_id
    FROM base_sales b
    WHERE b.ws_sales_price > 30
      AND b.wp_link_count > (SELECT MIN(wp3.wp_link_count) FROM web_page wp3 WHERE wp3.wp_type = 'order')
      AND EXISTS (
          SELECT 1 FROM web_page wp2
          WHERE wp2.wp_customer_sk = b.wp_customer_sk
            AND wp2.wp_type = 'order'
            AND wp2.wp_link_count >= 10
      )
    UNION ALL
    SELECT
        b.t_sub_shift,
        b.wp_type,
        'low' AS price_category,
        b.ws_sales_price,
        b.ws_net_profit,
        b.wp_web_page_id
    FROM base_sales b
    WHERE b.ws_sales_price <= 30
      AND b.wp_link_count > (SELECT MIN(wp3.wp_link_count) FROM web_page wp3 WHERE wp3.wp_type = 'order')
      AND EXISTS (
          SELECT 1 FROM web_page wp2
          WHERE wp2.wp_customer_sk = b.wp_customer_sk
            AND wp2.wp_type = 'order'
            AND wp2.wp_link_count >= 10
      )
) AS result
GROUP BY GROUPING SETS (
    (result.t_sub_shift, result.wp_type, result.price_category),
    (result.t_sub_shift, result.price_category),
    (result.wp_type, result.price_category),
    (result.price_category),
    ()
)
ORDER BY total_profit DESC
LIMIT 100
