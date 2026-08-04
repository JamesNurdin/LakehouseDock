WITH filtered_pages AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_customer_sk,
        wp.wp_type
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'JORDAN'
      AND regexp_like(wp.wp_url, '^https?://[^/]+/.*/[0-9]{4}')
      AND wp.wp_type LIKE 'A%'
)
SELECT
    ws.ws_warehouse_sk,
    sm.sm_carrier,
    concat(sm.sm_code, '_', sm.sm_carrier) AS shipping_info,
    regexp_extract(wp.wp_url, '([0-9]{4})') AS year_token,
    segment,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM filtered_pages wp
JOIN web_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(segment)
WHERE segment <> ''
GROUP BY
    ws.ws_warehouse_sk,
    sm.sm_carrier,
    concat(sm.sm_code, '_', sm.sm_carrier),
    regexp_extract(wp.wp_url, '([0-9]{4})'),
    segment
ORDER BY total_profit DESC
LIMIT 100
