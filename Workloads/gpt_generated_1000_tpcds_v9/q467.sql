WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM customer c
    WHERE REGEXP_LIKE(c.c_email_address, '.*@gmail\\.com$')
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    CONCAT('Store ', s.s_store_id, ' - Promo ', p.p_promo_id) AS store_promo_key,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_number_extracted
FROM filtered_customers fc
JOIN store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = fc.c_customer_sk
WHERE s.s_state LIKE 'C%'
  AND REGEXP_LIKE(p.p_promo_name, '^Promo.*')
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN reason r ON cr2.cr_reason_sk = r.r_reason_sk
        WHERE cr2.cr_refunded_customer_sk = fc.c_customer_sk
          AND r.r_reason_desc LIKE '%damaged%'
          AND cr2.cr_return_amount > 50
      )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    CONCAT('Store ', s.s_store_id, ' - Promo ', p.p_promo_id),
    REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1)
ORDER BY total_sales_net_paid DESC
LIMIT 100
