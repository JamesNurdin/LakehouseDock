SELECT
    cp.cp_type,
    s.s_state,
    ds.d_year AS start_year,
    (s.s_floor_space / 1000) AS floor_space_k,
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
    COUNT(DISTINCT p.p_promo_id)                     AS promo_cnt,
    SUM(p.p_cost)                                   AS total_promo_cost,
    AVG(i.i_wholesale_cost)                         AS avg_wholesale_cost,
    SUM(i.i_current_price - i.i_wholesale_cost)     AS total_gross_margin,
    SUM(p.p_cost * (1 + s.s_tax_percentage / 100))  AS total_cost_with_tax
FROM catalog_page cp
JOIN date_dim ds ON cp.cp_start_date_sk = ds.d_date_sk
JOIN date_dim de ON cp.cp_end_date_sk   = de.d_date_sk
JOIN promotion p
     ON p.p_start_date_sk = ds.d_date_sk
    AND p.p_end_date_sk   = de.d_date_sk
JOIN item i ON p.p_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = de.d_date_sk
WHERE cp.cp_type IS NOT NULL
  AND s.s_state IS NOT NULL
  AND ds.d_year >= 2015
GROUP BY
    cp.cp_type,
    s.s_state,
    ds.d_year,
    (s.s_floor_space / 1000),
    CASE WHEN s.s_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END
HAVING COUNT(DISTINCT p.p_promo_id) > 0
ORDER BY total_promo_cost DESC
LIMIT 100
