SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_market_desc,
    d.d_year AS return_year,
    hd_ret.hd_income_band_sk AS returning_income_band,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    wp.wp_type,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_quantity,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d_access.d_date_sk > d_creation.d_date_sk
  AND d.d_year = 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_market_desc,
    d.d_year,
    hd_ret.hd_income_band_sk,
    hd_ref.hd_income_band_sk,
    wp.wp_type
ORDER BY total_net_loss DESC
LIMIT 100
