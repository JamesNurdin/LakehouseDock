WITH store_data AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        p.p_promo_name,
        s.ss_net_profit AS net_profit,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^L')
      AND p.p_promo_name LIKE '%Discount%'
),
web_data AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        p.p_promo_name,
        w.ws_net_profit AS net_profit,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM web_sales w
    JOIN customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON w.ws_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^L')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    full_name,
    email_domain,
    COUNT(*) AS transaction_count,
    SUM(net_profit) AS total_net_profit,
    AVG(net_profit) AS avg_net_profit
FROM (
    SELECT full_name, email_domain, net_profit FROM store_data
    UNION ALL
    SELECT full_name, email_domain, net_profit FROM web_data
) AS combined
GROUP BY full_name, email_domain
ORDER BY total_net_profit DESC
LIMIT 100
