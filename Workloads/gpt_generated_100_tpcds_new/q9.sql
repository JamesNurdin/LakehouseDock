WITH base AS (
    SELECT
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_return_quantity AS cr_return_quantity,
        r.r_reason_desc AS r_reason_desc,
        c.c_customer_id AS c_customer_id,
        ca.ca_city AS ca_city,
        ca.ca_zip AS ca_zip,
        wp.wp_url AS wp_url,
        wp.wp_max_ad_count AS wp_max_ad_count
    FROM reason r
    RIGHT OUTER JOIN catalog_returns cr
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 20
      AND cr.cr_return_quantity >= 1
      AND r.r_reason_desc LIKE '%like%'
      AND ca.ca_zip IN ('49843','77752','12477')
      AND wp.wp_max_ad_count >= 1
),
agg AS (
    SELECT
        r_reason_desc,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM base
    GROUP BY r_reason_desc
)
SELECT DISTINCT
    b.r_reason_desc,
    b.c_customer_id,
    b.ca_city,
    b.ca_zip,
    b.wp_url,
    b.cr_return_amount,
    b.cr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY b.r_reason_desc ORDER BY b.cr_return_amount DESC) AS rn_per_reason,
    a.total_return_amount,
    RANK() OVER (ORDER BY a.total_return_amount DESC) AS reason_rank
FROM base b
JOIN agg a
    ON b.r_reason_desc = a.r_reason_desc
ORDER BY reason_rank, rn_per_reason
LIMIT 100
