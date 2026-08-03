-- Goal: Compare aggregated store return amounts across two fiscal years, categorizing return levels and providing the overall average return amount.
-- The query uses CUBE grouping, a Bernoulli sample, a scalar subquery, a CASE expression, and combines two filtered aggregates with a UNION.
WITH sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_year,
    d_quarter_name,
    sr_store_sk,
    SUM(sr_return_amt_inc_tax)         AS total_return_inc_tax,
    COUNT(*)                           AS return_cnt,
    CASE WHEN SUM(sr_return_amt_inc_tax) > 1000 THEN 'High' ELSE 'Low' END AS return_level,
    (SELECT AVG(sr3.sr_return_amt_inc_tax) FROM store_returns sr3) AS avg_return_amt
FROM sampled_returns sr1
JOIN date_dim d1 ON sr1.sr_returned_date_sk = d1.d_date_sk
WHERE d1.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  AND sr1.sr_return_amt_inc_tax > 100
GROUP BY CUBE (d1.d_year, d1.d_quarter_name, sr1.sr_store_sk)

UNION

SELECT
    d_year,
    d_quarter_name,
    sr_store_sk,
    SUM(sr_return_amt_inc_tax)         AS total_return_inc_tax,
    COUNT(*)                           AS return_cnt,
    CASE WHEN SUM(sr_return_amt_inc_tax) > 500 THEN 'High' ELSE 'Low' END AS return_level,
    (SELECT AVG(sr3.sr_return_amt_inc_tax) FROM store_returns sr3) AS avg_return_amt
FROM store_returns sr2
JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
WHERE d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND sr2.sr_return_quantity > 5
GROUP BY CUBE (d2.d_year, d2.d_quarter_name, sr2.sr_store_sk)

ORDER BY d_year ASC NULLS LAST,
         d_quarter_name ASC NULLS LAST,
         sr_store_sk ASC NULLS LAST,
         return_level ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
