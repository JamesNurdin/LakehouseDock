WITH dr_damaged AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    RIGHT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Package was damaged'
    GROUP BY w.w_warehouse_id, w.w_city, r.r_reason_desc
),
 dr_warranty AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    RIGHT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Did not like the warranty'
    GROUP BY w.w_warehouse_id, w.w_city, r.r_reason_desc
)
SELECT *
FROM dr_damaged
UNION ALL
SELECT *
FROM dr_warranty
LIMIT 100
