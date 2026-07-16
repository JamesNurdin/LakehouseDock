SELECT
    d.d_year,
    d.d_quarter_name,
    CASE WHEN MOD(d.d_month_seq, 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_fee) AS total_fees,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores,
    SUM(CASE WHEN hd_ret.hd_vehicle_count > 0 THEN 1 ELSE 0 END) AS returning_households_with_vehicle,
    SUM(CASE WHEN hd_ref.hd_income_band_sk IS NOT NULL THEN hd_ref.hd_income_band_sk ELSE 0 END) AS sum_income_band_refunded
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    CASE WHEN MOD(d.d_month_seq, 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING COUNT(*) > 100
ORDER BY d.d_year, d.d_quarter_name, month_parity
LIMIT 100
