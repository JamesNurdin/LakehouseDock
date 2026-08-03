WITH catalog_part AS (
    SELECT
        cc.cc_state AS state,
        cp.cp_department AS department,
        r.r_reason_desc AS reason_desc,
        CASE WHEN cr.cr_fee > 0 THEN 'Fee' ELSE 'NoFee' END AS fee_flag,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_qty,
        cr.cr_returned_date_sk AS returned_date_sk
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount > 500
      AND cr.cr_returned_date_sk IN (2450941, 2450948)
      AND i.inv_quantity_on_hand > 50
      AND cr.cr_ship_mode_sk IN (
          SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'
      )
),
store_web_union AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        sr.sr_addr_sk AS addr_sk,
        sr.sr_hdemo_sk AS hdemo_sk,
        sr.sr_reason_sk AS reason_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_qty,
        sr.sr_fee AS fee,
        sr.sr_returned_date_sk AS returned_date_sk
    FROM store_returns sr
    UNION ALL
    SELECT
        NULL AS store_sk,
        wr.wr_refunded_addr_sk AS addr_sk,
        wr.wr_refunded_hdemo_sk AS hdemo_sk,
        wr.wr_reason_sk AS reason_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_qty,
        wr.wr_fee AS fee,
        wr.wr_returned_date_sk AS returned_date_sk
    FROM web_returns wr
),
store_web_part AS (
    SELECT
        COALESCE(s.s_state, ca.ca_state) AS state,
        NULL AS department,
        r.r_reason_desc AS reason_desc,
        CASE WHEN swu.fee > 0 THEN 'Fee' ELSE 'NoFee' END AS fee_flag,
        swu.return_amount,
        swu.return_qty,
        swu.returned_date_sk
    FROM store_web_union swu
    LEFT JOIN store s ON swu.store_sk = s.s_store_sk
    JOIN reason r ON swu.reason_sk = r.r_reason_sk
    JOIN customer_address ca ON swu.addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON swu.hdemo_sk = hd.hd_demo_sk
    WHERE (s.s_state = 'CA' OR s.s_state IS NULL)
      AND swu.return_amount > 200
      AND swu.returned_date_sk = 2450941
      AND r.r_reason_desc = 'Customer Not Satisfied'
),
combined AS (
    SELECT state, department, reason_desc, fee_flag, return_amount, return_qty, returned_date_sk
    FROM catalog_part
    UNION DISTINCT
    SELECT state, department, reason_desc, fee_flag, return_amount, return_qty, returned_date_sk
    FROM store_web_part
)
SELECT
    state,
    department,
    reason_desc,
    fee_flag,
    COUNT(*) AS cnt_returns,
    SUM(return_amount) AS total_return_amount,
    AVG(return_amount) AS avg_return_amount,
    MIN(return_amount) AS min_return_amount,
    MAX(return_amount) AS max_return_amount,
    (SELECT COUNT(*) FROM inventory) AS total_inventory_rows
FROM combined
GROUP BY ROLLUP (state, department, reason_desc, fee_flag)
ORDER BY state, department, reason_desc
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
