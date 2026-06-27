WITH returns_2000 AS (
    SELECT
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_catalog_page_sk
    FROM catalog_returns
    JOIN date_dim
        ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2000
)
SELECT
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    r.r_reason_desc,
    cp.cp_department,
    COUNT(*) AS total_returns,
    SUM(rcr.cr_return_amount) AS total_return_amount,
    SUM(rcr.cr_net_loss) AS total_net_loss,
    AVG(rcr.cr_return_quantity) AS avg_return_quantity
FROM returns_2000 rcr
JOIN ship_mode sm
    ON rcr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON rcr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON rcr.cr_reason_sk = r.r_reason_sk
JOIN catalog_page cp
    ON rcr.cr_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY
    sm.sm_type,
    w.w_warehouse_name,
    r.r_reason_desc,
    cp.cp_department
ORDER BY total_net_loss DESC
LIMIT 100
