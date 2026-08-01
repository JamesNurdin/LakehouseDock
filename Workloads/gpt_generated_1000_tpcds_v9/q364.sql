WITH filtered_time AS (
    SELECT
        t_time_sk,
        t_shift,
        t_sub_shift,
        t_meal_time,
        CONCAT(t_shift, '_', t_sub_shift) AS shift_subshift,
        REGEXP_EXTRACT(t_time_id, '([0-9]+)', 1) AS time_id_numeric,
        t_am_pm
    FROM time_dim
    WHERE regexp_like(t_sub_shift, 'morning|evening')
      AND t_meal_time LIKE 'break%'
)
SELECT
    ft.t_shift,
    ft.t_meal_time,
    ft.shift_subshift,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    MIN(ft.time_id_numeric) AS min_time_id_numeric
FROM web_sales ws
CROSS JOIN LATERAL (
    SELECT * FROM filtered_time
    WHERE t_time_sk = ws.ws_sold_time_sk
) ft
GROUP BY GROUPING SETS (
    (ft.t_shift, ft.t_meal_time, ft.shift_subshift),
    (ft.t_shift, ft.t_meal_time),
    (ft.t_shift),
    (ft.t_meal_time),
    ()
)
ORDER BY ft.t_shift, ft.t_meal_time, ft.shift_subshift
LIMIT 100
