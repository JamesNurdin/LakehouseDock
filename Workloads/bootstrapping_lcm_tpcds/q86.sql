SELECT
    d.d_year,
    d.d_moy,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(CASE WHEN rd.hd_buy_potential = 'HIGH' THEN wr.wr_return_amt ELSE 0 END) AS high_buy_potential_return_amt,
    SUM(CASE WHEN rtd.hd_buy_potential = 'LOW' THEN wr.wr_return_amt ELSE 0 END) AS low_buy_potential_return_amt
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN household_demographics rd ON wr.wr_refunded_hdemo_sk = rd.hd_demo_sk
JOIN household_demographics rtd ON wr.wr_returning_hdemo_sk = rtd.hd_demo_sk
JOIN income_band ib ON rd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    d.d_year,
    d.d_moy,
    s.s_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
