WITH
    returns_agg AS (
        SELECT
            cr_call_center_sk,
            cr_ship_mode_sk,
            cr_warehouse_sk,
            cr_catalog_page_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_return_quantity) AS total_qty,
            COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_return_amount > 50                     -- predicate 1
          AND cr_return_quantity >= 5                  -- predicate 2
          AND cr_return_tax >= 0                       -- predicate 3
          AND cr_fee BETWEEN 0 AND 20                  -- predicate 4
          AND cr_return_ship_cost < 100                -- predicate 5
          AND cr_order_number BETWEEN 5267260 AND 5267300 -- predicate 6
        GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_warehouse_sk, cr_catalog_page_sk
    ),
    joined AS (
        SELECT
            cc.cc_call_center_id,
            cc.cc_state,
            w.w_warehouse_name,
            sm.sm_type,
            cp.cp_department,
            ra.total_return_amount,
            ra.total_qty,
            ra.return_cnt,
            CASE
                WHEN ra.total_qty > 30 THEN 'Large'
                WHEN ra.total_qty > 10 THEN 'Medium'
                ELSE 'Small'
            END AS qty_bucket
        FROM returns_agg ra
        JOIN call_center cc
          ON ra.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
          ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
          ON ra.cr_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_page cp
          ON ra.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cc.cc_state NOT IN ('CA', 'TX')
          AND cc.cc_call_center_id NOT IN (
                SELECT cc2.cc_call_center_id
                FROM call_center cc2
                WHERE cc2.cc_zip LIKE '7%'
          )
          AND EXISTS (
                SELECT 1
                FROM ship_mode sm2
                WHERE sm2.sm_carrier = sm.sm_carrier
                  AND sm2.sm_type = sm.sm_type
                  AND sm2.sm_code = '01'
          )
          AND cp.cp_catalog_number IN (4, 11, 14)
          AND sm.sm_carrier = 'UPS'
    )
SELECT
    j.cc_state,
    COUNT(*) AS num_centers,
    SUM(j.total_return_amount) AS state_total_return,
    AVG(j.total_qty) AS avg_qty_per_center,
    CASE
        WHEN SUM(j.total_return_amount) > (SELECT AVG(total_return_amount) FROM returns_agg)
        THEN 'AboveAvg'
        ELSE 'BelowAvg'
    END AS performance_category,
    (SELECT COUNT(DISTINCT w2.w_warehouse_id)
         FROM warehouse w2
         JOIN catalog_returns cr2 ON cr2.cr_warehouse_sk = w2.w_warehouse_sk
         JOIN call_center cc2 ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
         WHERE cc2.cc_state = j.cc_state) AS warehouses_in_state
FROM joined j
GROUP BY j.cc_state
HAVING SUM(j.total_return_amount) > 1000
ORDER BY state_total_return DESC
LIMIT 100
