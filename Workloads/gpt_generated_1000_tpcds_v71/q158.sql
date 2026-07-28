WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_paid,
        ws.ws_order_number,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(s.web_name, 'Shop')
      AND s.web_class LIKE 'A%'
      AND sm.sm_carrier = 'DHL'
)
SELECT
    s.web_name,
    sm.sm_carrier,
    COUNT(fs.ws_order_number) AS total_orders,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_net_paid) AS avg_net_paid,
    MAX(CASE WHEN fs.rn = 1 THEN fs.email_domain END) AS top_email_domain,
    ROW_NUMBER() OVER (ORDER BY SUM(fs.ws_net_paid) DESC) AS revenue_rank
FROM filtered_sales fs
JOIN web_site s ON fs.ws_web_site_sk = s.web_site_sk
JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY s.web_name, sm.sm_carrier
ORDER BY total_net_paid DESC
LIMIT 100
