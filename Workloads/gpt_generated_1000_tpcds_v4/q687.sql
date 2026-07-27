WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450875 AND 2450965
    GROUP BY w.w_warehouse_name, r.r_reason_desc
),
dept_returns AS (
    SELECT
        cp.cp_department,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_start_date_sk >= 2450875
      AND cp.cp_end_date_sk <= 2451180
    GROUP BY cp.cp_department, r.r_reason_desc
)
SELECT DISTINCT
    'Warehouse' AS level,
    wr.w_warehouse_name AS entity,
    wr.r_reason_desc AS reason,
    wr.total_return_amount,
    wr.return_cnt
FROM warehouse_returns wr
UNION ALL
SELECT DISTINCT
    'Department' AS level,
    dr.cp_department AS entity,
    dr.r_reason_desc AS reason,
    dr.total_return_amount,
    dr.return_cnt
FROM dept_returns dr
ORDER BY level, total_return_amount DESC
LIMIT 100
