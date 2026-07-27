WITH page_sales AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_url,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date > DATE '2000-01-01'
      AND wp.wp_type = 'Home'
      AND ws.ws_ship_date_sk BETWEEN 2451791 AND 2452734
      AND ws.ws_promo_sk IN (971, 804)
    GROUP BY wp.wp_web_page_sk, wp.wp_type, wp.wp_url
)
SELECT
    ps.wp_type,
    ps.wp_url,
    ps.distinct_orders,
    ps.total_sales,
    ps.avg_profit,
    ps.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY ps.wp_type ORDER BY ps.total_sales DESC) AS rn_type_rank
FROM page_sales ps
WHERE ps.total_sales > 1000
  AND ps.avg_profit > 0
  AND ps.total_quantity >= 10
  AND ps.distinct_orders >= 5
ORDER BY ps.total_sales DESC, ps.wp_type
LIMIT 100
