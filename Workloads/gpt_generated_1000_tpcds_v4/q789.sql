WITH filtered AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_store_credit,
        t.t_shift,
        t.t_sub_shift,
        t.t_time_id,
        CONCAT(t.t_shift, '-', t.t_sub_shift) AS shift_label,
        SUBSTRING(t.t_time_id, 1, 2) AS time_prefix
    FROM catalog_returns cr
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(t.t_sub_shift, '^(night|evening)$')
      AND t.t_time_id LIKE '0%'
      AND cr.cr_return_amount > 0
)
SELECT
    shift_label,
    time_prefix,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_store_credit) AS avg_store_credit
FROM filtered
GROUP BY shift_label, time_prefix
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
