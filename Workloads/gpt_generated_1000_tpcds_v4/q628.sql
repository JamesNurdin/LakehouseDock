WITH sales_with_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d{2})', 1) AS promo_code,
        wsite.web_city,
        ws.ws_promo_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(p.p_promo_name, '\\d{2}')
      AND wsite.web_suite_number LIKE 'Suite 2%'
      AND cd.cd_gender = 'F'
)
SELECT
    promo_code,
    p_promo_name,
    web_city,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    AVG(ws_quantity) AS avg_quantity
FROM sales_with_details
GROUP BY promo_code, p_promo_name, web_city
ORDER BY total_net_profit DESC
LIMIT 100
