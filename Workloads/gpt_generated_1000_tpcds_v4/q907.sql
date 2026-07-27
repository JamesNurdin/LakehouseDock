WITH sales_data AS (
    SELECT
        ss.ss_net_profit,
        ca.ca_state,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        p.p_promo_name,
        d.d_year
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND regexp_like(p.p_promo_name, '(?i)discount')
      AND c.c_first_name LIKE 'A%'
      AND d.d_year = 2002
)
SELECT
    ca_state,
    CONCAT(c_first_name, ' ', c_last_name) AS customer_full_name,
    regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    CASE
        WHEN SUM(ss_net_profit) > 10000 THEN 'High'
        WHEN SUM(ss_net_profit) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_data
GROUP BY
    ca_state,
    CONCAT(c_first_name, ' ', c_last_name),
    regexp_extract(c_email_address, '@(.+)$', 1)
ORDER BY total_profit DESC
LIMIT 100
