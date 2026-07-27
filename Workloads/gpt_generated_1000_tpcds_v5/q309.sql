WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT
    wr.w_warehouse_id,
    wr.w_warehouse_name,
    wr.total_return_amount,
    CASE
        WHEN wr.total_return_amount > (SELECT AVG(total_return_amount) FROM warehouse_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM warehouse_returns wr
WHERE wr.return_cnt >= 10

UNION ALL

SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE
        WHEN SUM(cr.cr_return_amount) > (SELECT AVG(total_return_amount) FROM warehouse_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE t.t_sub_shift = 'evening'
  AND cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_time_sk = cr.cr_returned_time_sk
    )
GROUP BY w.w_warehouse_id, w.w_warehouse_name
HAVING SUM(cr.cr_return_amount) > 1000
