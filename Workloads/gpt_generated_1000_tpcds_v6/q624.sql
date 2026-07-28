/* goal: Identify warehouses and call centers with the highest return amounts in 2001, enriched with inventory levels and promotion channel info, and rank them */
WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount)               AS total_return_amount,
        AVG(cr.cr_return_quantity)              AS avg_return_qty,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS unique_refunded_customers,
        d.d_year,
        d.d_day_name,
        cc.cc_gmt_offset,
        cp.cp_catalog_number AS catalog_num_filter,
        p.p_channel_event
    FROM catalog_returns cr
    JOIN call_center cc        ON cr.cr_call_center_sk   = cc.cc_call_center_sk
    JOIN catalog_page cp        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w            ON cr.cr_warehouse_sk    = w.w_warehouse_sk
    JOIN date_dim d             ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN promotion p            ON p.p_start_date_sk = d.d_date_sk
    GROUP BY
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        d.d_year,
        d.d_day_name,
        cc.cc_gmt_offset,
        cp.cp_catalog_number,
        p.p_channel_event
)
SELECT
    ra.w_warehouse_name,
    ra.cc_name,
    ra.cp_catalog_number,
    ra.total_return_amount,
    ra.avg_return_qty,
    ra.unique_refunded_customers,
    /* scalar sub‑query: total inventory on hand for the same warehouse (all dates) */
    (SELECT SUM(i.inv_quantity_on_hand)
       FROM inventory i
       WHERE i.inv_warehouse_sk = ra.cr_warehouse_sk) AS total_inventory_qty,
    CASE WHEN ra.total_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (ORDER BY ra.total_return_amount DESC) AS return_rank
FROM returns_agg ra
/* join inventory to bring in the date dimension for the inventory row that matches the return date */
JOIN inventory inv
    ON inv.inv_warehouse_sk = ra.cr_warehouse_sk
   AND inv.inv_date_sk      = ra.cr_returned_date_sk
WHERE
    ra.d_year = 2001
    AND ra.d_day_name = 'Saturday'
    AND ra.cc_gmt_offset = -5.00
    AND ra.cp_catalog_number IN (19, 16)
    AND ra.p_channel_event = 'N'
ORDER BY return_rank
LIMIT 100
