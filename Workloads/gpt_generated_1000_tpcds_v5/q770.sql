WITH returned_customers AS (
    SELECT DISTINCT sr_customer_sk
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 500
)
SELECT
    sm.sm_ship_mode_id,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_net_profit) AS avg_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    REGEXP_EXTRACT(c.c_last_name, '^([A-Za-z]{3})', 1) AS last_name_prefix,
    CASE WHEN REGEXP_LIKE(ca.ca_suite_number, '\\d') THEN 'HasDigit' ELSE 'NoDigit' END AS suite_digit_flag,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE ca.ca_address_id LIKE 'AAAAAAAA%AAA'
  AND REGEXP_LIKE(wp.wp_url, '^https?://.*example\\.com')
  AND c.c_customer_sk IN (SELECT sr_customer_sk FROM returned_customers)
GROUP BY
    sm.sm_ship_mode_id,
    REGEXP_EXTRACT(c.c_last_name, '^([A-Za-z]{3})', 1),
    CASE WHEN REGEXP_LIKE(ca.ca_suite_number, '\\d') THEN 'HasDigit' ELSE 'NoDigit' END,
    CONCAT(ca.ca_city, ', ', ca.ca_state)
ORDER BY total_profit DESC
LIMIT 100
