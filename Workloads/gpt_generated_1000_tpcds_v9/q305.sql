WITH wh_subagg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        td.t_sub_shift,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        td.t_sub_shift IN ('morning', 'afternoon')
        AND td.t_am_pm = 'PM'
        AND (w.w_street_type IN ('Ave', 'Parkway') OR w.w_warehouse_sk IS NULL)
        AND cr.cr_call_center_sk IN (25, 31)
        AND cr.cr_return_quantity > 0
        AND cr.cr_return_amount > 10
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        td.t_sub_shift
)
SELECT
    w_warehouse_sk,
    w_warehouse_name,
    t_sub_shift,
    total_return_qty,
    total_return_amount,
    return_count,
    CASE WHEN total_return_amount > 1500 THEN 'High' ELSE 'Low' END AS amount_category,
    AVG(total_return_amount) OVER (PARTITION BY t_sub_shift) AS avg_amount_by_shift,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn_by_amount
FROM wh_subagg
WHERE total_return_qty > (
    SELECT AVG(total_return_qty) FROM wh_subagg
)
ORDER BY total_return_amount DESC
LIMIT 100
