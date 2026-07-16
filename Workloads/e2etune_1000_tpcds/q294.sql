SELECT
    cp.cp_department,
    t.t_hour,
    t.t_meal_time,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_cost,
    AVG(p.p_cost) AS avg_cost,
    MIN(p.p_cost) AS min_cost,
    MAX(p.p_cost) AS max_cost,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_cnt
FROM
    catalog_page cp
JOIN promotion p
    ON p.p_start_date_sk <= cp.cp_end_date_sk
   AND p.p_end_date_sk >= cp.cp_start_date_sk
JOIN time_dim t
    ON p.p_start_date_sk = t.t_time_sk
LEFT JOIN warehouse w
    ON p.p_item_sk = w.w_warehouse_sk
WHERE
    cp.cp_department IS NOT NULL
    AND p.p_cost > 0
GROUP BY
    cp.cp_department,
    t.t_hour,
    t.t_meal_time
HAVING
    SUM(p.p_cost) > 5000
ORDER BY
    total_cost DESC
LIMIT 50
