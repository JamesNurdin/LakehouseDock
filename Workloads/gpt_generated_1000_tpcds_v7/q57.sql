WITH returns_monthly AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        p.cp_type,
        SUM(r.cr_return_amount) AS total_return_amount,
        SUM(r.cr_return_quantity) AS total_return_qty
    FROM catalog_returns r
    JOIN catalog_page p ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
    JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
    WHERE p.cp_type = 'monthly'
      AND w.w_county = 'Williamson County'
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, p.cp_type
),
returns_quarterly AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        p.cp_type,
        SUM(r.cr_return_amount) AS total_return_amount,
        SUM(r.cr_return_quantity) AS total_return_qty
    FROM catalog_returns r
    JOIN catalog_page p ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
    JOIN warehouse w ON r.cr_warehouse_sk = w.w_warehouse_sk
    WHERE p.cp_type = 'quarterly'
      AND w.w_county = 'Ziebach County'
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, p.cp_type
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    cp_type,
    total_return_amount,
    total_return_qty
FROM returns_monthly
UNION ALL
SELECT
    w_warehouse_id,
    w_warehouse_name,
    cp_type,
    total_return_amount,
    total_return_qty
FROM returns_quarterly
ORDER BY total_return_amount DESC
LIMIT 100
