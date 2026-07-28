WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        cr.cr_order_number,
        cr.cr_item_sk,
        cp.cp_department,
        sm.sm_type,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        ws.ws_order_number
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count > 1
      AND cr.cr_return_amount > 100
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = cr.cr_item_sk
            AND wr2.wr_order_number = cr.cr_order_number
      )
)
SELECT
    cp_department,
    sm_type,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_quantity,
    AVG(cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount,
    GROUPING(cp_department) AS grp_department,
    GROUPING(sm_type) AS grp_ship_type
FROM filtered_returns
GROUP BY GROUPING SETS ( (cp_department, sm_type), (cp_department), () )
HAVING SUM(cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
