SELECT
    cp.cp_department,
    s.s_state,
    d_ret.d_year AS return_year,
    d_cp_end.d_year AS cp_end_year,
    d_closed.d_month_seq AS closed_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(p_start.p_cost) AS total_promo_cost_start,
    SUM(p_end.p_cost) AS total_promo_cost_end,
    SUM(CASE WHEN p_start.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS start_discount_active_cnt,
    SUM(CASE WHEN p_end.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS end_discount_active_cnt,
    (d_ret.d_year - d_cp_end.d_year) AS year_gap
FROM
    store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN promotion p_start
    ON p_start.p_start_date_sk = d_ret.d_date_sk
JOIN promotion p_end
    ON p_end.p_end_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year >= 2015
GROUP BY
    cp.cp_department,
    s.s_state,
    d_ret.d_year,
    d_cp_end.d_year,
    d_closed.d_month_seq
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
