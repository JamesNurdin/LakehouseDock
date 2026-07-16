SELECT
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_moy,
    COUNT(DISTINCT c_ret.c_customer_id) AS distinct_returning_customers,
    COUNT(DISTINCT c_ref.c_customer_id) AS distinct_refunded_customers,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN hd_ret.hd_income_band_sk = 5 THEN wr.wr_return_amt ELSE 0 END) AS income_band_5_return_amount,
    SUM(CASE WHEN hd_ret.hd_vehicle_count >= 2 THEN wr.wr_return_quantity ELSE 0 END) AS returns_from_multi_vehicle_hh,
    COUNT(*) FILTER (WHERE wr.wr_return_quantity > 1) AS multi_item_returns,
    SUM(CASE WHEN hd_cust.hd_buy_potential = 'High' THEN wr.wr_return_amt ELSE 0 END) AS high_buy_potential_return_amount
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_cust
    ON c_ret.c_current_hdemo_sk = hd_cust.hd_demo_sk
WHERE d_ret.d_year >= 2020
GROUP BY ROLLUP (s.s_store_id, s.s_city, d_ret.d_year, d_ret.d_moy)
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
