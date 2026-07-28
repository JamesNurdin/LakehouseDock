WITH page_sales AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_coupon_amt) AS avg_coupon
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        ws.ws_ext_wholesale_cost > 500
        AND ws.ws_coupon_amt < 300
        AND wp.wp_rec_end_date >= DATE '2000-01-01'
        AND wp.wp_type IN ('HOME', 'PRODUCT', 'CONTENT', 'CATEGORY')
        AND ws.ws_web_site_sk IN (1, 13, 45)
    GROUP BY wp.wp_web_page_sk, wp.wp_type
)
SELECT
    ps.wp_type,
    COUNT(DISTINCT ps.wp_web_page_sk) AS page_count,
    SUM(ps.total_sales) AS sum_sales,
    AVG(ps.total_profit) AS avg_profit_per_page,
    MAX(ps.avg_coupon) AS max_avg_coupon
FROM page_sales ps
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws2
    WHERE ws2.ws_web_page_sk = ps.wp_web_page_sk
      AND ws2.ws_coupon_amt > 500
)
GROUP BY ps.wp_type
HAVING SUM(ps.total_sales) > 10000
ORDER BY sum_sales DESC
LIMIT 100
