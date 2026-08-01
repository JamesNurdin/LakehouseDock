WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_last_name, ', ', c.c_first_name) AS full_name,
        REGEXP_EXTRACT(c.c_email_address, '^(.+)@(.+)$', 2) AS email_domain,
        REGEXP_EXTRACT(c.c_email_address, '^(.+)@(.+)$', 1) AS email_user,
        SUBSTRING(c.c_email_address FROM 1 FOR 5) AS email_prefix
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(c.c_email_address, '@example\\.com$')
        AND ca.ca_zip LIKE '75___'
)
SELECT 
    fc.ca_state,
    fc.ca_city,
    COUNT(DISTINCT fc.c_customer_sk) AS num_customers,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    MAX(d.d_date) AS latest_sold_date,
    MIN(t.t_time) AS earliest_sold_time,
    MIN(fc.email_prefix) AS sample_email_prefix
FROM filtered_customers fc
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = fc.c_customer_sk
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE t.t_am_pm = 'PM'
    AND p.p_promo_name LIKE '%Summer%'
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = fc.c_customer_sk
    )
GROUP BY fc.ca_state, fc.ca_city
ORDER BY total_net_paid DESC
LIMIT 100
