WITH base_join AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        i.i_item_id,
        i.i_formulation,
        i.i_current_price,
        i.i_size,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_code,
        sm.sm_carrier,
        w.w_warehouse_name,
        r.r_reason_desc,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE sm.sm_code = 'AIR'
      AND i.i_formulation LIKE '%steel%'
      AND r.r_reason_desc = 'Damaged'
),
agg1 AS (
    SELECT
        i_item_id,
        cp_department,
        sm_code,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amt,
        AVG(cr_return_amount) AS avg_return_amt,
        COUNT(*) AS return_cnt
    FROM base_join
    GROUP BY i_item_id, cp_department, sm_code
),
final AS (
    SELECT
        a.i_item_id,
        a.cp_department,
        a.sm_code,
        a.total_return_qty,
        a.total_return_amt,
        a.avg_return_amt,
        a.return_cnt,
        SUM(a.total_return_amt) OVER (PARTITION BY a.cp_department) AS dept_total_return_amt,
        ROW_NUMBER() OVER (ORDER BY a.total_return_amt DESC) AS rn
    FROM agg1 a
    WHERE a.total_return_qty > (
        SELECT AVG(b.total_return_qty)
        FROM agg1 b
        WHERE b.cp_department = a.cp_department
    )
)
SELECT
    i_item_id,
    cp_department,
    sm_code,
    total_return_qty,
    total_return_amt,
    avg_return_amt,
    return_cnt,
    dept_total_return_amt,
    rn
FROM final
ORDER BY dept_total_return_amt DESC, i_item_id
LIMIT 100
