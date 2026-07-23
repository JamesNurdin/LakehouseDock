SELECT
    wsite.web_name AS web_site_name,
    p.p_promo_name,
    CONCAT(wsite.web_name, ' - ', p.p_promo_name) AS site_promo_label,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1) AS discount_percent,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS total_sales
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND REGEXP_LIKE(p.p_promo_name, '(?i)discount')
    AND wsite.web_name LIKE '%Online%'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND d2.d_date >= DATE '2025-01-01'
    )
GROUP BY
    wsite.web_name,
    p.p_promo_name,
    CONCAT(wsite.web_name, ' - ', p.p_promo_name),
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1)
HAVING
    SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
