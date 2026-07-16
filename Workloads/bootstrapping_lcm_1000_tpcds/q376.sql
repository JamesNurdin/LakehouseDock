SELECT
    d_ps.d_fy_year AS promo_fy_year,
    d_ps.d_quarter_name AS promo_quarter,
    (d_ps.d_fy_year * 100 + d_ps.d_fy_quarter_seq) AS year_quarter_code,
    s.s_state AS store_state,
    w.web_state AS website_state,
    CASE WHEN s.s_state = w.web_state THEN 'Same_State' ELSE 'Diff_State' END AS state_similarity,
    i.i_category AS item_category,
    i.i_brand AS item_brand,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(i.i_wholesale_cost) AS total_wholesale,
    SUM(i.i_current_price - i.i_wholesale_cost) AS total_gross_margin,
    MIN(d_ps.d_date) AS earliest_promo_start,
    MAX(d_pe.d_date) AS latest_promo_end,
    AVG(date_diff('day', d_ps.d_date, d_pe.d_date)) AS avg_promo_duration_days,
    SUM(p.p_cost) / NULLIF(SUM(i.i_wholesale_cost), 0) AS promo_cost_to_wholesale_ratio,
    COUNT(*) FILTER (WHERE d_ps.d_quarter_seq = d_pe.d_quarter_seq) AS promo_same_quarter_cnt,
    COUNT(*) FILTER (WHERE d_ps.d_quarter_seq <> d_pe.d_quarter_seq) AS promo_cross_quarter_cnt
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_ps ON p.p_start_date_sk = d_ps.d_date_sk
JOIN date_dim d_pe ON p.p_end_date_sk = d_pe.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ps.d_date_sk
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d_ps.d_date_sk
                 AND w.web_close_date_sk = d_pe.d_date_sk
JOIN date_dim d_web_open ON w.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close ON w.web_close_date_sk = d_web_close.d_date_sk
GROUP BY
    d_ps.d_fy_year,
    d_ps.d_quarter_name,
    d_ps.d_fy_quarter_seq,
    s.s_state,
    w.web_state,
    CASE WHEN s.s_state = w.web_state THEN 'Same_State' ELSE 'Diff_State' END,
    i.i_category,
    i.i_brand,
    (d_ps.d_fy_year * 100 + d_ps.d_fy_quarter_seq)
HAVING COUNT(DISTINCT p.p_promo_id) > 0
ORDER BY total_promo_cost DESC
LIMIT 100
