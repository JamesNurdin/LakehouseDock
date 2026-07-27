WITH joined_data AS (
   SELECT
       cr.cr_returned_time_sk,
       cr.cr_return_amount,
       cr.cr_return_amt_inc_tax,
       cr.cr_order_number,
       t.t_shift,
       t.t_time_id,
       t.t_meal_time,
       regexp_extract(t.t_time_id, '(\\d{2})', 1) AS hour_part,
       concat(t.t_shift, '-', t.t_meal_time) AS shift_meal
   FROM catalog_returns cr
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE regexp_like(t.t_shift, '^(first|second)$')
     AND t.t_time_id LIKE '%:%:%'
),
agg_data AS (
   SELECT
       shift_meal,
       t_shift,
       hour_part,
       COUNT(*) AS returns_cnt,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(cr_return_amt_inc_tax) AS total_inc_tax
   FROM joined_data
   GROUP BY shift_meal, t_shift, hour_part
)
SELECT
    shift_meal,
    t_shift,
    hour_part,
    returns_cnt,
    total_return_amount,
    total_inc_tax,
    SUM(total_return_amount) OVER (
        PARTITION BY t_shift
        ORDER BY CAST(hour_part AS integer)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_shift
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 100
