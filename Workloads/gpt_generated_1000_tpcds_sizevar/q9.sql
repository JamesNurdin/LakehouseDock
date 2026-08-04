WITH filtered_time AS (
    SELECT
        t_time_sk,
        t_shift,
        t_sub_shift,
        t_meal_time,
        t_time_id,
        concat(t_shift, '-', t_sub_shift) AS shift_sub,
        regexp_extract(t_time_id, '(\\d{2})$', 1) AS time_id_suffix
    FROM tpcds.time_dim
    WHERE regexp_like(t_shift, '^M.*')               -- shifts that start with "M" (e.g., "morning")
      AND t_meal_time LIKE '%breakfast%'
)
SELECT
    ft.shift_sub,
    ft.time_id_suffix,
    COUNT(wr.wr_order_number) AS orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
FROM filtered_time ft
JOIN tpcds.web_returns wr
    ON wr.wr_returned_time_sk = ft.t_time_sk
WHERE wr.wr_return_amt > 20
GROUP BY ft.shift_sub, ft.time_id_suffix
ORDER BY total_return_amt DESC
LIMIT 100
