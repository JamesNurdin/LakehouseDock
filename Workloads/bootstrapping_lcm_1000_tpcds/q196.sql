SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ret.hd_income_band_sk AS returning_income_band,
    wp.wp_type,
    wp.wp_url,
    d_cre.d_date AS page_creation_date,
    d_acc.d_date AS page_access_date,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_quantity
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_cre
    ON wp.wp_creation_date_sk = d_cre.d_date_sk
LEFT JOIN date_dim d_acc
    ON wp.wp_access_date_sk = d_acc.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    hd_ref.hd_buy_potential,
    hd_ref.hd_income_band_sk,
    hd_ret.hd_buy_potential,
    hd_ret.hd_income_band_sk,
    wp.wp_type,
    wp.wp_url,
    d_cre.d_date,
    d_acc.d_date
ORDER BY total_net_loss DESC
LIMIT 100
