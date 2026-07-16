SELECT
    d_sr.d_year AS store_return_year,
    s.s_state AS store_state,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 'Excellent' ELSE 'Other' END AS credit_rating_group,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(*) AS total_return_records,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_purchase_estimate > 5000 THEN 1 ELSE 0 END) AS high_purchase_estimate_cnt
FROM customer_demographics cd
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_store.d_year >= 2015
  AND (sr.sr_return_amt > 100 OR wr.wr_return_amt > 150)
GROUP BY
    d_sr.d_year,
    s.s_state,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 'Excellent' ELSE 'Other' END
ORDER BY total_store_net_loss DESC
LIMIT 100
