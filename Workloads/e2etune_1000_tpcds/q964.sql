WITH warehouse_agg AS (
    SELECT
        w.w_city,
        w.w_state,
        COUNT(*) AS warehouse_cnt,
        SUM(w.w_warehouse_sq_ft) AS total_warehouse_sq_ft,
        AVG(w.w_warehouse_sq_ft) AS avg_warehouse_sq_ft
    FROM warehouse w
    WHERE w.w_warehouse_sq_ft > 500000
    GROUP BY w.w_city, w.w_state
),
store_agg AS (
    SELECT
        s.s_city,
        s.s_state,
        COUNT(*) AS store_cnt,
        SUM(s.s_floor_space) AS total_store_floor_space,
        AVG(s.s_floor_space) AS avg_store_floor_space
    FROM store s
    WHERE s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_floor_space > 5000000
    GROUP BY s.s_city, s.s_state
)
SELECT
    sa.s_city,
    sa.s_state,
    sa.store_cnt,
    sa.total_store_floor_space,
    wa.warehouse_cnt,
    wa.total_warehouse_sq_ft,
    ROUND(sa.total_store_floor_space / NULLIF(wa.total_warehouse_sq_ft, 0), 4) AS floor_to_warehouse_ratio,
    ROW_NUMBER() OVER (ORDER BY sa.total_store_floor_space DESC) AS rn
FROM store_agg sa
JOIN warehouse_agg wa
    ON sa.s_city = wa.w_city
   AND sa.s_state = wa.w_state
WHERE wa.warehouse_cnt >= 1
ORDER BY floor_to_warehouse_ratio DESC
LIMIT 20
