WITH gmail_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        CONCAT(s.s_store_name, '_', CAST(d_ret.d_year AS VARCHAR)) AS store_year_key,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'gmail' AS email_domain,
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@', 1) AS email_user
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.+@gmail\\.com$')
      AND s.s_store_name LIKE '%Market%'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        CONCAT(s.s_store_name, '_', CAST(d_ret.d_year AS VARCHAR)),
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@', 1)
    HAVING SUM(cr.cr_net_loss) > (
        SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2
    )
),

yahoo_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        CONCAT(s.s_store_name, '_', CAST(d_ret.d_year AS VARCHAR)) AS store_year_key,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'yahoo' AS email_domain,
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@', 1) AS email_user
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.+@yahoo\\.com$')
      AND s.s_store_name LIKE '%Market%'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        CONCAT(s.s_store_name, '_', CAST(d_ret.d_year AS VARCHAR)),
        REGEXP_EXTRACT(c.c_email_address, '([^@]+)@', 1)
    HAVING SUM(cr.cr_net_loss) > (
        SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2
    )
)
SELECT *
FROM (
    SELECT * FROM gmail_returns
    UNION ALL
    SELECT * FROM yahoo_returns
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
