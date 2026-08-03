WITH sampled_store AS (
    SELECT *
    FROM store TABLESAMPLE BERNOULLI (10)
),
store_returns_agg AS (
    SELECT d.d_year AS year,
           SUM(sr.sr_return_amt) AS total_return_amount,
           'store' AS source
    FROM sampled_store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE s.s_number_employees > (
        SELECT AVG(s2.s_number_employees)
        FROM store s2
    )
      AND d.d_year BETWEEN 1900 AND 1920
    GROUP BY d.d_year
),
catalog_returns_agg AS (
    SELECT d.d_year AS year,
           SUM(cr.cr_return_amount) AS total_return_amount,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_gmt_offset > 0
      AND d.d_year BETWEEN 1900 AND 1920
    GROUP BY d.d_year
)
SELECT year,
       total_return_amount,
       source
FROM store_returns_agg
UNION ALL
SELECT year,
       total_return_amount,
       source
FROM catalog_returns_agg
ORDER BY year ASC,
         total_return_amount DESC
LIMIT 100
