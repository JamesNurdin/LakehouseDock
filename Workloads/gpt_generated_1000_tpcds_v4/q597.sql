WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_email_address,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain
    FROM customer
    WHERE regexp_like(c_email_address, '@example\\.com$')
)
SELECT
    year,
    reason_desc,
    SUM(loss) AS total_loss,
    COUNT(*) AS return_count,
    CASE WHEN SUM(loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category
FROM (
    SELECT
        dr.d_year AS year,
        rs.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN reason rs ON cr.cr_reason_sk = rs.r_reason_sk
    JOIN filtered_customers fc ON cr.cr_refunded_customer_sk = fc.c_customer_sk
    WHERE rs.r_reason_desc LIKE '%damage%'

    UNION ALL

    SELECT
        dr.d_year AS year,
        rs.r_reason_desc AS reason_desc,
        wr.wr_net_loss AS loss
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN reason rs ON wr.wr_reason_sk = rs.r_reason_sk
    JOIN filtered_customers fc ON wr.wr_refunded_customer_sk = fc.c_customer_sk
    WHERE rs.r_reason_desc LIKE '%damage%'
) t
GROUP BY year, reason_desc
HAVING SUM(loss) > 5000
ORDER BY total_loss DESC
LIMIT 100
