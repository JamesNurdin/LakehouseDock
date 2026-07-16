SELECT
    cc.cc_state,
    s.s_state,
    EXTRACT(year FROM dd_cc_closed.d_date) AS closed_year,
    CASE
        WHEN dd_cc_open.d_month_seq <= 6 THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END AS open_half,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    MAX(dd_p_end.d_date) AS latest_promo_end_date,
    COUNT(*) AS total_rows
FROM call_center cc
JOIN date_dim dd_cc_closed
    ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_cc_open
    ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_p_end
    ON p.p_end_date_sk = dd_p_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_cc_closed.d_date_sk
JOIN date_dim dd_store_closed
    ON s.s_closed_date_sk = dd_store_closed.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND dd_cc_closed.d_year = 2022
GROUP BY
    cc.cc_state,
    s.s_state,
    EXTRACT(year FROM dd_cc_closed.d_date),
    CASE
        WHEN dd_cc_open.d_month_seq <= 6 THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END
HAVING COUNT(DISTINCT cc.cc_call_center_id) > 0
ORDER BY total_rows DESC
LIMIT 100
