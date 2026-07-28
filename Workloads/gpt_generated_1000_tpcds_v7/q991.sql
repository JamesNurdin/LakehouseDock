SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    SUM(cs.cs_ext_sales_price) AS total_amount,
    'sales' AS metric_type
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY d.d_year, d.d_month_seq

UNION ALL

SELECT
    d.d_year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_return_amount) AS total_amount,
    'returns' AS metric_type
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2002
  AND r.r_reason_desc LIKE '%price%'
GROUP BY d.d_year, d.d_month_seq

ORDER BY d_year, month_seq, metric_type
LIMIT 100
