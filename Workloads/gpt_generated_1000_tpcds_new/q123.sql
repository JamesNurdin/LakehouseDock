WITH catalog_ret AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        cr.cr_return_amount AS return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
),
web_ret AS (
    SELECT
        d.d_date AS return_date,
        i.i_item_id AS item_id,
        wr.wr_return_amt_inc_tax AS return_amount,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
)
SELECT
    return_date,
    SUM(return_amount) AS total_return_amount,
    SUM(SUM(return_amount)) OVER (
        ORDER BY return_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT return_date, return_amount FROM catalog_ret
    UNION ALL
    SELECT return_date, return_amount FROM web_ret
) AS combined
GROUP BY return_date
ORDER BY return_date
