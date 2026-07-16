SELECT
    s.s_store_id,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MAX(cr.cr_return_tax) AS max_return_tax,
    (SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_quantity), 0)) AS loss_per_item
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2015
  AND t.t_hour BETWEEN 9 AND 17
  AND cd_ref.cd_gender = 'F'
GROUP BY
    s.s_store_id,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    cd_ref.cd_gender,
    cd_ret.cd_gender
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
