SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_id,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month_seq,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month_seq,
    i.inv_quantity_on_hand,
    p.p_cost,
    p.p_promo_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(i.inv_quantity_on_hand) OVER (PARTITION BY s.s_state, cp.cp_department) AS state_dept_inventory,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY p.p_cost DESC) AS promo_rank_by_dept
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_start.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
   AND p.p_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
WHERE cp.cp_type = 'Seasonal'
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND i.inv_quantity_on_hand > 0
ORDER BY cp.cp_department, p.p_cost DESC
LIMIT 100
