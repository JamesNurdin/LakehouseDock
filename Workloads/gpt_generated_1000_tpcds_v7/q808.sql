WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY r.r_reason_desc, d.d_year
    HAVING SUM(cr.cr_return_amount) > 1000
),
store_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        'Store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY r.r_reason_desc, d.d_year
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT reason, year, total_return_amount, source
FROM catalog_agg
UNION ALL
SELECT reason, year, total_return_amount, source
FROM store_agg
ORDER BY year, total_return_amount DESC
