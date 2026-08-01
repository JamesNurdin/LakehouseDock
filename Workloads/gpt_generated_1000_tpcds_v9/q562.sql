WITH sales_join AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        t.t_hour,
        t.t_shift,
        t.t_meal_time,
        CONCAT(t.t_shift, '_', t.t_meal_time) AS shift_meal,
        REGEXP_EXTRACT(t.t_time_id, '(\\d+)', 1) AS time_id_num,
        SUBSTR(t.t_time_id, 1, 4) AS time_id_prefix
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        CONCAT(t.t_shift, '_', t.t_meal_time) LIKE 'first_%'
        AND REGEXP_LIKE(t.t_time_id, '^T[0-9]{6}$')
),
aggregated AS (
    SELECT
        sj.t_hour,
        sj.t_shift,
        sj.shift_meal,
        SUM(sj.ss_ext_sales_price) AS total_sales,
        SUM(sj.ss_net_profit) AS total_profit,
        AVG(sj.ss_ext_discount_amt) AS avg_discount,
        -- Correlated scalar subquery: average sales price for the same hour
        (SELECT AVG(sj_inner.ss_ext_sales_price)
         FROM sales_join sj_inner
         WHERE sj_inner.t_hour = sj.t_hour) AS avg_sales_same_hour,
        -- Correlated EXISTS subquery: flag if any high‑quantity sale (>10) exists for this shift_meal
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM sales_join sj_exist
                WHERE sj_exist.t_shift = sj.t_shift
                  AND sj_exist.shift_meal = sj.shift_meal
                  AND sj_exist.ss_quantity > 10
            ) THEN 1 ELSE 0
        END AS high_quantity_exists
    FROM sales_join sj
    GROUP BY GROUPING SETS (
        (sj.t_hour, sj.t_shift, sj.shift_meal),
        (sj.t_hour, sj.t_shift),
        (sj.t_hour),
        ()
    )
)
SELECT
    t_hour,
    t_shift,
    shift_meal,
    total_sales,
    total_profit,
    avg_discount,
    avg_sales_same_hour,
    high_quantity_exists
FROM aggregated
ORDER BY
    t_hour,
    t_shift,
    shift_meal
LIMIT 100
