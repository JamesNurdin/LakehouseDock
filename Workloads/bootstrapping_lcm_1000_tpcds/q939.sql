SELECT
    cc.cc_country,
    s.s_state,
    d_open.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    i.i_category,
    CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Cheap' END AS price_tier,
    COUNT(DISTINCT p.p_promo_id) AS num_promotions,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(i.i_current_price - i.i_wholesale_cost) AS total_margin,
    AVG(p.p_cost / NULLIF(i.i_current_price, 0)) AS avg_cost_to_price_ratio,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(CASE WHEN i.i_current_price > 100 THEN 1 ELSE 0 END) AS high_price_items,
    SUM(CASE WHEN i.i_category = 'Electronics' THEN 1 ELSE 0 END) AS electronics_items,
    SUM(CASE WHEN i.i_category = 'Furniture' THEN 1 ELSE 0 END) AS furniture_items
FROM call_center cc
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_open.d_date_sk
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
WHERE cc.cc_tax_percentage > 0
  AND s.s_tax_percentage > 0
  AND i.i_current_price IS NOT NULL
GROUP BY
    cc.cc_country,
    s.s_state,
    d_open.d_year,
    d_end.d_year,
    i.i_category,
    CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Cheap' END
HAVING SUM(p.p_cost) > 10000
ORDER BY total_promo_cost DESC
LIMIT 100
