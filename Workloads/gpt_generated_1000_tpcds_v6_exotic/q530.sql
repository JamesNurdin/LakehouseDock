WITH cr_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_carrier AS carrier,
        d.d_year AS year,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND regexp_like(c.c_email_address, '^.+@.+\\..+$')
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        d.d_year,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1)
)
SELECT
    ship_mode_id,
    carrier,
    year,
    total_returns,
    total_return_amount,
    total_net_loss,
    email_domain
FROM cr_agg
WHERE total_return_amount > (SELECT AVG(total_return_amount) FROM cr_agg)
  AND email_domain LIKE '%.com'
ORDER BY total_return_amount DESC
LIMIT 100
