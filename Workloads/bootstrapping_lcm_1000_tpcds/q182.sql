SELECT
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_state,
    s.s_city,
    cd_ref.cd_gender,
    cd_ret.cd_marital_status,
    COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_quantity) AS total_quantity,
    ROUND(AVG(cr.cr_return_tax), 2) AS avg_return_tax
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND cr.cr_return_amount > 0
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    s.s_state,
    s.s_city,
    cd_ref.cd_gender,
    cd_ret.cd_marital_status
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
