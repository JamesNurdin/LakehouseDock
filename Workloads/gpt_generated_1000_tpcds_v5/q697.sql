WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        w.w_warehouse_sk,
        w.w_state,
        cc.cc_state,
        cp.cp_department,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid,
        AVG(cs.cs_sales_price) AS avg_price,
        COUNT(*) AS sales_cnt,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_type
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_sales_price BETWEEN 50 AND 200
      AND hd.hd_income_band_sk IN (7, 15, 20)
      AND w.w_state = 'CA'
    GROUP BY
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        w.w_warehouse_sk,
        w.w_state,
        cc.cc_state,
        cp.cp_department,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END
)
SELECT
    sa.cs_order_number,
    sa.cs_sold_date_sk,
    sa.w_state,
    sa.cc_state,
    sa.cp_department,
    sa.total_paid,
    sa.avg_price,
    sa.sales_cnt,
    sa.quantity_type,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    SUM(sa.total_paid) OVER (PARTITION BY sa.w_state ORDER BY sa.total_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_paid,
    RANK() OVER (PARTITION BY sa.w_state ORDER BY sa.total_paid DESC) AS state_rank,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        JOIN reason r2 ON cr2.cr_reason_sk = r2.r_reason_sk
        WHERE cr2.cr_order_number = sa.cs_order_number
          AND r2.r_reason_desc LIKE '%Defect%'
    ) AS defect_return_cnt
FROM sales_agg sa
JOIN catalog_returns cr ON cr.cr_order_number = sa.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_warehouse_sk = sa.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    JOIN reason r3 ON cr3.cr_reason_sk = r3.r_reason_sk
    WHERE cr3.cr_order_number = sa.cs_order_number
      AND r3.r_reason_desc LIKE '%Defect%'
)
  AND inv.inv_quantity_on_hand > 500
ORDER BY sa.total_paid DESC
LIMIT 100
