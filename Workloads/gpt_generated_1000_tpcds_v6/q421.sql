WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq IN (5, 7, 13)
    GROUP BY d.d_year
    HAVING SUM(cr.cr_return_amount) > 0
),
store_agg AS (
    SELECT
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq IN (5, 7, 13)
    GROUP BY d.d_year
    HAVING SUM(sr.sr_return_amt) > 0
)
SELECT DISTINCT
    combined.year,
    combined.source,
    combined.total_return_amount,
    combined.avg_return_quantity,
    combined.distinct_customers,
    CASE WHEN combined.total_return_amount > 100000 THEN 'high' ELSE 'low' END AS return_level
FROM (
    SELECT year, 'catalog' AS source, total_return_amount, avg_return_quantity, distinct_customers
    FROM catalog_agg
    UNION ALL
    SELECT year, 'store' AS source, total_return_amount, avg_return_quantity, distinct_customers
    FROM store_agg
) AS combined
ORDER BY combined.year DESC, combined.source
LIMIT 100
