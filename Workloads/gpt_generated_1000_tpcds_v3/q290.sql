SELECT
    s_fact.s_state,
    d_ret.d_year,
    c.cp_department,
    w.web_mkt_class,
    hd.hd_buy_potential,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(CASE WHEN sr.sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_return_count,
    COUNT(*) AS total_returns
FROM store_returns sr
INNER JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN store s_fact ON sr.sr_store_sk = s_fact.s_store_sk
INNER JOIN store s_alt ON sr.sr_store_sk = s_alt.s_store_sk
INNER JOIN date_dim d_store_closed ON s_fact.s_closed_date_sk = d_store_closed.d_date_sk
INNER JOIN catalog_page c ON c.cp_start_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_cp_end ON c.cp_end_date_sk = d_cp_end.d_date_sk
INNER JOIN web_site w ON w.web_open_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_web_close ON w.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    s_fact.s_state,
    d_ret.d_year,
    c.cp_department,
    w.web_mkt_class,
    hd.hd_buy_potential,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amount DESC
LIMIT 100
