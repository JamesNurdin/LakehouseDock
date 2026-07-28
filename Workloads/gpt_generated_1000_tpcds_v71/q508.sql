WITH filtered_sales AS (
    SELECT DISTINCT
        ws.ws_order_number,
        ws.ws_net_paid,
        c.c_customer_id,
        sm.sm_type,
        sm.sm_contract,
        d.d_year,
        wp.wp_url
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND regexp_like(wp.wp_url, '^https?://.*example\\.com')
      AND sm.sm_type LIKE 'EXPRESS%'
      AND substring(sm.sm_contract, 1, 1) = 'A'
)
SELECT
    d_year,
    sm_type,
    regexp_extract(wp_url, 'https?://([^/]+)/', 1) AS domain,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(ws_net_paid) AS total_net_paid
FROM filtered_sales
GROUP BY d_year, sm_type, regexp_extract(wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_net_paid DESC
LIMIT 100
