SELECT
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_day_name,
    hd_returning.hd_dep_count,
    hd_returning.hd_vehicle_count,
    hd_refunded.hd_buy_potential,
    s.s_state,
    s.s_city,
    s.s_floor_space,
    s.s_tax_percentage,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_cost,
    date_diff('day', d_return.d_date, d_end.d_date) AS promo_duration_days,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    CASE
        WHEN hd_returning.hd_buy_potential = 'HIGH' THEN 'HighPotential'
        WHEN hd_returning.hd_buy_potential = 'MEDIUM' THEN 'MediumPotential'
        ELSE 'LowPotential'
    END AS buy_potential_category,
    (s.s_floor_space * s.s_tax_percentage) AS floor_space_tax_value,
    (SUM(wr.wr_return_amt) / NULLIF(p.p_cost, 0)) AS return_to_promo_cost_ratio
FROM web_returns wr
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_return.d_year = 2022
  AND s.s_state IS NOT NULL
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_day_name,
    d_return.d_date,
    d_end.d_date,
    hd_returning.hd_dep_count,
    hd_returning.hd_vehicle_count,
    hd_returning.hd_buy_potential,
    hd_refunded.hd_buy_potential,
    s.s_state,
    s.s_city,
    s.s_floor_space,
    s.s_tax_percentage,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_cost
ORDER BY total_return_amt DESC
LIMIT 100
