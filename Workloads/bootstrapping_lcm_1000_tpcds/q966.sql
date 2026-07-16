SELECT
    s.s_store_id,
    d.d_year,
    CASE WHEN d.d_quarter_seq % 2 = 0 THEN 'EvenQuarter' ELSE 'OddQuarter' END AS quarter_parity,
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_marital_status AS returning_marital_status,
    ca_ret.ca_state AS returning_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_store_credit) AS total_store_credit,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(SUM(cr.cr_return_amount), 0), 2) AS loss_to_return_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE d.d_year BETWEEN 2000 AND 2020
  AND cd_ret.cd_gender = 'F'
GROUP BY
    s.s_store_id,
    d.d_year,
    CASE WHEN d.d_quarter_seq % 2 = 0 THEN 'EvenQuarter' ELSE 'OddQuarter' END,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    ca_ret.ca_state
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
