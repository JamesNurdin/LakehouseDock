SELECT
    state,
    county,
    store_count,
    avg_store_employees,
    total_warehouse_sqft,
    min_warehouse_sqft,
    max_warehouse_sqft,
    RANK() OVER (ORDER BY total_warehouse_sqft DESC) AS state_warehouse_rank
FROM (
    SELECT
        s.s_state AS state,
        s.s_county AS county,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        AVG(s.s_number_employees) AS avg_store_employees,
        SUM(w.w_warehouse_sq_ft) AS total_warehouse_sqft,
        MIN(w.w_warehouse_sq_ft) AS min_warehouse_sqft,
        MAX(w.w_warehouse_sq_ft) AS max_warehouse_sqft
    FROM store s
    JOIN warehouse w
        ON s.s_state = w.w_state
       AND s.s_zip = w.w_zip
    JOIN time_dim t
        ON t.t_hour = 12
    WHERE s.s_rec_end_date IS NULL
    GROUP BY s.s_state, s.s_county
    HAVING SUM(w.w_warehouse_sq_ft) > 500000
       AND AVG(s.s_number_employees) > 200
) agg
ORDER BY total_warehouse_sqft DESC
LIMIT 100
