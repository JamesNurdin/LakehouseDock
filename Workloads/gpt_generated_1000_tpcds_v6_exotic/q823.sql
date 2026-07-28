WITH sales_returns AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_ext_sales_price AS amount,
        ss.ss_quantity AS quantity,
        CAST('sale' AS varchar) AS record_type
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 100
      AND ss.ss_quantity > 0
    UNION ALL
    SELECT 
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amt_inc_tax AS amount,
        cr.cr_return_quantity AS quantity,
        CAST('return' AS varchar) AS record_type
    FROM catalog_returns cr
    WHERE cr.cr_return_amt_inc_tax > 100
      AND cr.cr_return_quantity > 0
)
SELECT 
    d.d_year,
    d.d_month_seq,
    sr.record_type,
    SUM(sr.amount) AS total_amount,
    SUM(sr.quantity) AS total_quantity,
    COUNT(*) AS transaction_count,
    AVG(sr.amount) AS avg_amount
FROM sales_returns sr
JOIN date_dim d ON sr.date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND d.d_dom = 15
GROUP BY d.d_year, d.d_month_seq, sr.record_type
HAVING SUM(sr.amount) > 1000
ORDER BY d.d_year, d.d_month_seq, sr.record_type
LIMIT 100
