WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_email_address,
        regexp_extract(c.c_email_address, '([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})', 2) AS email_domain,
        c.c_first_name,
        c.c_last_name
    FROM tpcds.customer AS c
    WHERE regexp_like(c.c_email_address, '^([A-Za-z0-9._%+-]+)@example\\.com$')
      AND c.c_first_name LIKE 'A%'
      AND substring(c.c_last_name, 1, 1) = 'S'
),
joined_data AS (
    SELECT
        fc.email_domain,
        hd.hd_buy_potential,
        cr.cr_net_loss,
        cr.cr_return_amount
    FROM filtered_customers AS fc
    JOIN tpcds.catalog_returns AS cr
        ON cr.cr_refunded_customer_sk = fc.c_customer_sk
    JOIN tpcds.household_demographics AS hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
)
SELECT
    email_domain,
    hd_buy_potential,
    COUNT(*) AS returns_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount
FROM joined_data
GROUP BY email_domain, hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
