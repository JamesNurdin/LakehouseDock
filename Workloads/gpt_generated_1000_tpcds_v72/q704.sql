WITH sales_with_domain AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        d.d_year,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)') AS domain,
        wp.wp_type AS wp_type,
        sm.sm_type AS sm_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND regexp_like(wp.wp_url, '^https?://.*\\.com')
      AND wp.wp_autogen_flag = 'N'
)
SELECT
    domain,
    wp_type,
    sm_type,
    CONCAT(domain, '-', wp_type) AS domain_type_key,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS num_sales,
    SUM(ws_ext_sales_price) AS total_sales
FROM sales_with_domain
GROUP BY domain, wp_type, sm_type, CONCAT(domain, '-', wp_type)
HAVING SUM(ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
