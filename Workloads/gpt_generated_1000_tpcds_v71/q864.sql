WITH
    base AS (
        SELECT
            cr.cr_returned_date_sk AS return_date_key,
            cp.cp_department,
            sm.sm_carrier,
            w.w_warehouse_name,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_net_loss
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE EXISTS (
                SELECT 1
                FROM customer_demographics cd
                WHERE cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
                  AND cd.cd_marital_status = 'M'
                  AND cd.cd_dep_employed_count >= 2
            )
          AND cr.cr_return_amount > 100
          AND cr.cr_return_quantity >= 2
          AND sm.sm_carrier IN ('BOXBUNDLES', 'MSC')
          AND w.w_state = 'CA'
    ),
    other AS (
        SELECT
            cr.cr_returned_date_sk AS return_date_key,
            cp.cp_department,
            sm.sm_carrier,
            w.w_warehouse_name,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_net_loss
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE EXISTS (
                SELECT 1
                FROM customer_demographics cd
                WHERE cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
                  AND cd.cd_purchase_estimate BETWEEN 3000 AND 8000
            )
          AND cr.cr_return_amount BETWEEN 50 AND 200
          AND cr.cr_return_quantity = 1
          AND sm.sm_carrier = 'PRIVATECARRIER'
          AND w.w_state = 'TX'
    ),
    unioned AS (
        SELECT * FROM base
        UNION ALL
        SELECT * FROM other
    )
SELECT
    return_date_key,
    cp_department,
    sm_carrier,
    w_warehouse_name,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_quantity,
    SUM(cr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY cp_department ORDER BY SUM(cr_net_loss) DESC) AS dept_net_loss_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(cr_return_amount) DESC) AS overall_amount_rank
FROM unioned
GROUP BY
    return_date_key,
    cp_department,
    sm_carrier,
    w_warehouse_name
ORDER BY total_net_loss DESC
LIMIT 100
