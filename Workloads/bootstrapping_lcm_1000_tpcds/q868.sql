SELECT
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    s.s_state,
    s.s_city,
    refunded_cd.cd_gender AS refunded_gender,
    returning_cd.cd_marital_status AS returning_marital_status,
    COUNT(*) AS return_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    (SUM(cr.cr_return_amount) - SUM(cr.cr_fee) - SUM(cr.cr_refunded_cash)) AS net_return_value,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN cr.cr_return_tax ELSE 0 END) AS total_return_tax
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics refunded_cd
    ON cr.cr_refunded_cdemo_sk = refunded_cd.cd_demo_sk
JOIN customer_demographics returning_cd
    ON cr.cr_returning_cdemo_sk = returning_cd.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    s.s_state,
    s.s_city,
    refunded_cd.cd_gender,
    returning_cd.cd_marital_status
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
