WITH avg_return_by_ship AS (
    SELECT sm.sm_ship_mode_sk,
           AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
    GROUP BY sm.sm_ship_mode_sk
)
SELECT
    cr.cr_returning_customer_sk,
    c.c_first_name,
    c.c_last_name,
    w.w_warehouse_name,
    d.d_year,
    cr.cr_return_amount,
    CASE 
        WHEN cr.cr_return_amount > 1000 THEN 'High'
        WHEN cr.cr_return_amount > 100 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cr.cr_return_amount DESC) AS rn_warehouse,
    RANK() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_rank,
    avg_ship.avg_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN avg_return_by_ship avg_ship ON sm.sm_ship_mode_sk = avg_ship.sm_ship_mode_sk
WHERE d.d_fy_year = 1912
  AND d.d_qoy = 2
  AND w.w_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND sm.sm_contract = 'HVDFCcQ'
  AND cr.cr_return_amount > 50
  AND cr.cr_return_quantity >= 1
ORDER BY w.w_warehouse_name, rn_warehouse
LIMIT 100
