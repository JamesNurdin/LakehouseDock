SELECT
    s.s_store_id,
    s.s_city,
    d_sr.d_year AS return_year,
    d_sr.d_month_seq AS return_month_seq,
    cd_sr.cd_gender AS store_return_gender,
    cd_wr_ret.cd_gender AS returning_gender,
    cd_wr_ref.cd_gender AS refunded_gender,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_web_customers,
    AVG(cd_sr.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
         ELSE SUM(sr.sr_return_amt) / SUM(wr.wr_return_amt) END AS store_to_web_return_ratio
FROM
    store_returns AS sr
    JOIN date_dim AS d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics AS cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN store AS s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim AS d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_returns AS wr ON wr.wr_returned_date_sk = d_sr.d_date_sk
    JOIN date_dim AS d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN customer_demographics AS cd_wr_ret ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
    JOIN customer_demographics AS cd_wr_ref ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
WHERE
    d_sr.d_year BETWEEN 2020 AND 2022
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sr.d_year,
    d_sr.d_month_seq,
    cd_sr.cd_gender,
    cd_wr_ret.cd_gender,
    cd_wr_ref.cd_gender
HAVING
    SUM(sr.sr_return_amt) > 5000
ORDER BY
    total_store_return_amt DESC
LIMIT 100
