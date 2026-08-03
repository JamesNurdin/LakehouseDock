WITH daily_returns AS (
    SELECT
        cr_returned_date_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS sum_return_amount,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    dr.cnt_returns,
    dr.sum_return_amount,
    wp.wp_web_page_id,
    wp.wp_url,
    RANK() OVER (ORDER BY dr.sum_return_amount DESC NULLS LAST) AS return_amount_rank
FROM web_page wp
RIGHT OUTER JOIN date_dim d
    ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN daily_returns dr
    ON dr.cr_returned_date_sk = d.d_date_sk
WHERE
    wp.wp_autogen_flag = 'N'
    AND d.d_year = 2001
    AND wp.wp_url LIKE 'http%'
    AND dr.cnt_returns IS NOT NULL
    AND wp.wp_customer_sk IN (
        SELECT cr_refunded_customer_sk
        FROM catalog_returns
        WHERE cr_return_amount > 200
    )
ORDER BY return_amount_rank
LIMIT 100
