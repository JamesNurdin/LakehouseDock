SELECT
    d.d_year,
    cd_refunded.cd_gender,
    cd_refunded.cd_education_status,
    CASE WHEN wr.wr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END AS amt_category,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    MIN(wr.wr_return_tax) AS min_return_tax,
    MAX(wr.wr_return_amt_inc_tax) AS max_return_amt_inc_tax
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE d.d_quarter_name = '1902Q1'
  AND d.d_current_year = 'Y'
  AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND cd_refunded.cd_gender = 'F'
  AND cd_refunded.cd_education_status = 'College'
  AND cd_refunded.cd_dep_employed_count >= 1
  AND wr.wr_return_quantity > 10
  AND wr.wr_return_amt > 100.00
  AND wr.wr_returned_time_sk IN (48347, 23325)
GROUP BY d.d_year,
    cd_refunded.cd_gender,
    cd_refunded.cd_education_status,
    CASE WHEN wr.wr_return_amt_inc_tax > 500 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amount DESC
LIMIT 100
