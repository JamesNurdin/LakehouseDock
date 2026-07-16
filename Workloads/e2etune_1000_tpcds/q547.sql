WITH returns_agg AS (
    SELECT
        cr_catalog_page_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY cr_catalog_page_sk, cr_ship_mode_sk, cr_warehouse_sk
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    cp.cp_department,
    cp.cp_type,
    sm.sm_type AS ship_mode_type,
    w.w_country,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.total_quantity,
    ra.return_cnt,
    ra.avg_return_amount,
    CASE WHEN ra.total_return_amount != 0 THEN ra.total_net_loss / ra.total_return_amount ELSE NULL END AS net_loss_ratio,
    SUM(ra.total_return_amount) OVER (PARTITION BY cp.cp_department) AS dept_total_return_amount,
    CASE WHEN SUM(ra.total_return_amount) OVER (PARTITION BY cp.cp_department) != 0 THEN ra.total_return_amount / SUM(ra.total_return_amount) OVER (PARTITION BY cp.cp_department) ELSE NULL END AS dept_return_share,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY ra.total_return_amount DESC) AS dept_return_rank
FROM returns_agg ra
JOIN catalog_page cp ON ra.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ra.cr_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_type = 'monthly'
  AND sm.sm_type IN ('AIR', 'GROUND')
ORDER BY ra.total_return_amount DESC
LIMIT 100
