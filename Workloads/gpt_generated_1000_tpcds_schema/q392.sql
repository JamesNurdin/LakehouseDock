WITH catalog_agg AS (
    SELECT
        'catalog' AS source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT i.i_brand) AS distinct_brands
    FROM
        catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2000
),
store_agg AS (
    SELECT
        'store' AS source,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT i.i_brand) AS distinct_brands
    FROM
        store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2000
)
SELECT
    source,
    total_return_amount,
    distinct_brands
FROM (
    SELECT source, total_return_amount, distinct_brands FROM catalog_agg
    UNION
    SELECT source, total_return_amount, distinct_brands FROM store_agg
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
