SELECT
    d_start.d_year,
    d_start.d_month_seq,
    s.s_state,
    CASE 
        WHEN i.i_category = 'Electronics' THEN 'Electronics'
        WHEN i.i_category = 'Clothing'    THEN 'Clothing'
        ELSE 'Other'
    END AS cat_group,
    COUNT(DISTINCT p.p_promo_id)               AS promo_cnt,
    SUM(p.p_cost)                              AS total_cost,
    AVG(p.p_cost)                              AS avg_cost,
    SUM(date_diff('day', d_start.d_date, d_end.d_date)) AS total_promo_days,
    COUNT(*) FILTER (WHERE p.p_discount_active = 'Y')   AS active_discount_cnt,
    SUM(p.p_cost) / NULLIF(COUNT(*), 0)       AS avg_cost_per_promo
FROM promotion p
JOIN item i
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
WHERE d_start.d_year >= 2010
GROUP BY
    d_start.d_year,
    d_start.d_month_seq,
    s.s_state,
    CASE 
        WHEN i.i_category = 'Electronics' THEN 'Electronics'
        WHEN i.i_category = 'Clothing'    THEN 'Clothing'
        ELSE 'Other'
    END
ORDER BY total_cost DESC
LIMIT 100
