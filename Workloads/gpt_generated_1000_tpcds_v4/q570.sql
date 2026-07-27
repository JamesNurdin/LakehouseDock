WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        td.t_hour,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_return_quantity) AS sum_return_qty,
        COUNT(*) AS cnt_returns,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(inv.inv_quantity_on_hand) AS sum_inventory_qty
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cp.cp_department IN ('Electronics', 'Home', 'Sports')
      AND w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND cr.cr_return_amount > 20
      AND cr.cr_return_quantity >= 1
      AND inv.inv_quantity_on_hand > 50
    GROUP BY
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_state,
        r.r_reason_desc,
        td.t_hour
)
SELECT
    b.cp_department,
    AVG(b.sum_return_amount) AS avg_sum_return_amount,
    SUM(b.sum_return_qty) AS total_return_qty,
    COUNT(DISTINCT b.w_warehouse_name) AS warehouse_count,
    MAX(b.sum_return_amount) AS max_sum_return_amount,
    ROW_NUMBER() OVER (ORDER BY AVG(b.sum_return_amount) DESC) AS dept_rank,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        JOIN warehouse w2 ON inv2.inv_warehouse_sk = w2.w_warehouse_sk
        WHERE w2.w_state = 'CA'
    ) AS total_ca_inventory
FROM base b
WHERE b.sum_return_amount > 200
  AND b.sum_inventory_qty > 100
GROUP BY b.cp_department
HAVING COUNT(*) >= 2
ORDER BY avg_sum_return_amount DESC
LIMIT 100
