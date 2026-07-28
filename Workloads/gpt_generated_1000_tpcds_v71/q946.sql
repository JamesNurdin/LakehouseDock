WITH cs_filtered AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3,}')
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@(.*)$', 1) AS email_domain,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promo_count
FROM cs_filtered cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE c.c_first_name LIKE 'A%'
  AND regexp_like(c.c_email_address, '@example\\.com$')
  AND p.p_promo_name LIKE '%Clearance%'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
ORDER BY total_net_profit DESC
LIMIT 100
