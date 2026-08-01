WITH returns_by_dept AS (
    SELECT
        cp.cp_department AS department,
        w.w_city AS attribute,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city IN (SELECT w_city FROM warehouse WHERE w_city = 'Greenwood')
    GROUP BY cp.cp_department, w.w_city
),
returns_by_shipmode AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_type AS attribute,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE EXISTS (
        SELECT 1 FROM warehouse w2
        WHERE w2.w_warehouse_sk = cr.cr_warehouse_sk
          AND w2.w_country = 'USA'
    )
    GROUP BY cp.cp_department, sm.sm_type
),
union_returns AS (
    SELECT department, attribute, total_return_amount, return_cnt FROM (
        SELECT department, attribute, total_return_amount, return_cnt FROM returns_by_dept
        UNION ALL
        SELECT department, attribute, total_return_amount, return_cnt FROM returns_by_shipmode
    )
)
SELECT
    ur.department,
    ur.attribute,
    ur.total_return_amount,
    ur.return_cnt,
    cw.w_warehouse_name
FROM union_returns ur
FULL OUTER JOIN warehouse cw
    ON ur.attribute = cw.w_city
ORDER BY ur.total_return_amount DESC
LIMIT 100
