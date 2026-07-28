WITH catalog AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        i.i_category,
        cr.cr_return_amount AS return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (5, 6, 7)
),
store AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        i.i_category,
        sr.sr_return_amt AS return_amount,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (5, 6, 7)
)
SELECT
    source,
    i_category,
    SUM(return_amount) AS total_return_amount,
    COUNT(*) AS return_transactions
FROM (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM store
) combined
GROUP BY source, i_category
ORDER BY source, total_return_amount DESC
