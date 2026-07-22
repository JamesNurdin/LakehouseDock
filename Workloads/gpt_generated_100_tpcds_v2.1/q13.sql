SELECT
    d.d_quarter_seq,
    cd_ret.cd_education_status,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN tpcds.customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
WHERE d.d_weekend = 'N'
  AND d.d_quarter_seq = 9
  AND cd_ret.cd_education_status = 'College'
  AND cr.cr_net_loss > 100.00
GROUP BY d.d_quarter_seq, cd_ret.cd_education_status
ORDER BY total_net_loss DESC, d.d_quarter_seq
LIMIT 100
