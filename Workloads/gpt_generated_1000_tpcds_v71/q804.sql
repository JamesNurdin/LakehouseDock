WITH sales_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        p.p_promo_id,
        p.p_promo_name,
        cs.cs_net_profit,
        cr.cr_return_amount
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
          AND p.p_channel_catalog = 'Y'
          AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    sr.c_customer_id,
    concat_ws(' ', sr.c_first_name, sr.c_last_name) AS full_name,
    regexp_extract(sr.c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain,
    COUNT(DISTINCT sr.p_promo_id) AS distinct_promotions,
    SUM(sr.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.cr_return_amount, 0)) AS total_return_amount,
    CASE WHEN regexp_like(sr.c_email_address, '\\.com$') THEN 'Corporate' ELSE 'Other' END AS email_type
FROM sales_returns sr
GROUP BY
    sr.c_customer_id,
    sr.c_first_name,
    sr.c_last_name,
    sr.c_email_address
ORDER BY total_net_profit DESC
LIMIT 100
