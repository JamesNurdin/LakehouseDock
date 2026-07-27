WITH sales_home AS (
    SELECT
        wp.wp_url AS page_url,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'home'
      AND ws.ws_net_profit > 1000
      AND wp.wp_rec_end_date >= DATE '2000-01-01'
    GROUP BY wp.wp_url
    HAVING SUM(ws.ws_net_paid_inc_tax) > 5000
),
sales_recent AS (
    SELECT
        wp.wp_url AS page_url,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_creation_date_sk > 2450800
      AND ws.ws_promo_sk IN (871, 202, 999)
    GROUP BY wp.wp_url
    HAVING COUNT(DISTINCT ws.ws_order_number) >= 5
)
SELECT DISTINCT u.page_url,
                u.total_sales,
                u.distinct_orders
FROM (
    SELECT page_url, total_sales, distinct_orders FROM sales_home
    UNION ALL
    SELECT page_url, total_sales, distinct_orders FROM sales_recent
) AS u
ORDER BY u.total_sales DESC
LIMIT 100
