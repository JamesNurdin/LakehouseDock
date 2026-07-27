WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_details,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        c.c_email_address
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(p.p_channel_details, '(?i)family')
      AND p.p_promo_name LIKE '%Discount%'
      AND regexp_like(c.c_email_address, '@[A-Za-z0-9.-]+\\.com$')
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    regexp_extract(ps.p_channel_details, '(family|young|old)', 1) AS extracted_keyword,
    SUM(ps.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ps.ws_bill_customer_sk) AS unique_customers,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_profit_all
FROM promo_sales ps
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws3
    WHERE ws3.ws_promo_sk = ps.ws_promo_sk
      AND ws3.ws_quantity > 5
)
GROUP BY
    ps.p_promo_id,
    ps.p_promo_name,
    regexp_extract(ps.p_channel_details, '(family|young|old)', 1)
HAVING SUM(ps.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
