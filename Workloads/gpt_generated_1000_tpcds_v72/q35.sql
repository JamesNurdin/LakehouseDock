WITH sales_cust AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(ss.ss_ticket_number) AS sales_cnt,
        SUM(ss.ss_net_paid) AS total_spent,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})', 1) AS promo_year
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '^Holiday.*')
      AND c.c_email_address LIKE '%@example.com'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        c.c_customer_id,
        c.c_email_address,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1),
        CONCAT(c.c_first_name, ' ', c.c_last_name),
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})', 1)
),
returns_cust AS (
    SELECT
        c.c_customer_id,
        c.c_email_address,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(sr.sr_ticket_number) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_returned,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})', 1) AS promo_year
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '^Holiday.*')
      AND sr.sr_return_amt > 0
    GROUP BY
        c.c_customer_id,
        c.c_email_address,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1),
        CONCAT(c.c_first_name, ' ', c.c_last_name),
        REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})', 1)
)
SELECT
    c_customer_id,
    email_domain,
    full_name,
    sales_cnt,
    total_spent,
    return_cnt,
    total_returned,
    promo_year
FROM (
    SELECT
        c_customer_id,
        email_domain,
        full_name,
        sales_cnt,
        total_spent,
        NULL AS return_cnt,
        NULL AS total_returned,
        promo_year
    FROM sales_cust
    UNION DISTINCT
    SELECT
        c_customer_id,
        email_domain,
        full_name,
        NULL,
        NULL,
        return_cnt,
        total_returned,
        promo_year
    FROM returns_cust
) AS combined
ORDER BY c_customer_id
