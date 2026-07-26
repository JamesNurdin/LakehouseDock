WITH dept_returns AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        d_start.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    GROUP BY cp.cp_department, cp.cp_type, d_start.d_year
)
SELECT
    cp_department,
    cp_type,
    d_year,
    total_return_amt,
    CASE
        WHEN total_return_amt >= 50000 THEN 'Very High'
        WHEN total_return_amt >= 20000 THEN 'High'
        WHEN total_return_amt >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_bucket,
    DENSE_RANK() OVER (PARTITION BY cp_type ORDER BY total_return_amt DESC) AS dept_rank_within_type,
    total_return_amt * 1.0 / SUM(total_return_amt) OVER (PARTITION BY cp_type) AS pct_of_type_total
FROM dept_returns
ORDER BY cp_type, dept_rank_within_type
