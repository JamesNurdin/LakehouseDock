SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    s.s_store_name,
    t.t_hour,
    t.t_meal_time,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_reversed_charge) AS total_reversed_charge,
    SUM(cr.cr_store_credit) AS total_store_credit
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    s.s_store_name,
    t.t_hour,
    t.t_meal_time
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
