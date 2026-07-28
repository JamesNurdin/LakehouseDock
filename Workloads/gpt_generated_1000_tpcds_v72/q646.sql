WITH returns_with_customer AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_ship_mode_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_email_address,
        cs.cs_promo_sk,
        p.p_promo_name,
        sm.sm_type
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND c.c_customer_id LIKE 'A%'
)
SELECT
    p_promo_name,
    sm_type,
    COUNT(*) AS return_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    regexp_extract(c_email_address, '@(.*)$', 1) AS email_domain,
    concat(c_first_name, ' ', c_last_name) AS full_name
FROM returns_with_customer
GROUP BY
    p_promo_name,
    sm_type,
    regexp_extract(c_email_address, '@(.*)$', 1),
    concat(c_first_name, ' ', c_last_name)
ORDER BY total_net_loss DESC
LIMIT 100
