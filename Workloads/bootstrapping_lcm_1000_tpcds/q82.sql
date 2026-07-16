SELECT
    s.s_state AS store_state,
    cc.cc_division_name,
    dd.d_quarter_name,
    i.i_category,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN i.i_color = 'Red' THEN 1 ELSE 0 END) AS red_item_count,
    SUM(CASE WHEN p.p_channel_tv = 'Y' THEN p.p_cost ELSE 0 END) AS tv_channel_cost
FROM store s
JOIN date_dim dd
    ON s.s_closed_date_sk = dd.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = dd.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = dd.d_date_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
WHERE dd.d_year BETWEEN 2000 AND 2020
    AND s.s_state IS NOT NULL
    AND i.i_current_price > 0
GROUP BY
    s.s_state,
    cc.cc_division_name,
    dd.d_quarter_name,
    i.i_category
HAVING SUM(p.p_cost) > 1000
ORDER BY total_promo_cost DESC
LIMIT 100
