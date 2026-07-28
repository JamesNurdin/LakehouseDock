WITH store_sales_agg AS (
    SELECT
        'store' AS sales_channel,
        s.s_state AS region,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_tax_percentage BETWEEN 0.05 AND 0.10
      AND t.t_hour BETWEEN 9 AND 17
),
web_sales_agg AS (
    SELECT
        'web' AS sales_channel,
        c.c_birth_country AS region,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE wp.wp_link_count > 10
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    sales_channel,
    region,
    SUM(net_paid) AS total_net_paid
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
) u
GROUP BY sales_channel, region
HAVING SUM(net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
