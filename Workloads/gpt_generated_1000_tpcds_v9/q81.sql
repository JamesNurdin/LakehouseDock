WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        MIN(REGEXP_EXTRACT(c.c_email_address, '@(.+)$')) AS email_domain_sample,
        MIN(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_sample,
        MIN(SUBSTR(i.i_item_desc, 1, 30)) AS item_desc_sample
    FROM
        catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE
        regexp_like(i.i_item_desc, 'Deluxe')
        AND c.c_email_address LIKE '%@example.com'
        AND d.d_year = 2002
    GROUP BY
        r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        MIN(REGEXP_EXTRACT(c.c_email_address, '@(.+)$')) AS email_domain_sample,
        MIN(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_sample,
        MIN(SUBSTR(i.i_item_desc, 1, 30)) AS item_desc_sample
    FROM
        web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        regexp_like(i.i_item_desc, 'Deluxe')
        AND c.c_email_address LIKE '%@example.com'
        AND d.d_year = 2002
    GROUP BY
        r.r_reason_desc
)
SELECT DISTINCT
    reason_desc,
    channel,
    total_net_loss,
    distinct_customers,
    email_domain_sample,
    full_name_sample,
    item_desc_sample
FROM (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
ORDER BY total_net_loss DESC
LIMIT 100
