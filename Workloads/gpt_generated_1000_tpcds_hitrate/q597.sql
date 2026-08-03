/* goal: Calculate total net loss and related metrics per store, warehouse and catalog department for 2001 returns, focusing on defective reasons, while excluding stores in Seattle and only including stores that are not in CA, and comparing store GMT offset against the maximum offset of CA call centers. */
WITH store_non_ca AS (
    SELECT s1.s_store_id
    FROM store s1
    EXCEPT
    SELECT s2.s_store_id
    FROM store s2
    WHERE s2.s_state = 'CA'
),
filtered_cr AS (
    SELECT cr.*, d_cr.d_year, d_cr.d_weekend, cp.cp_department, r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d_cr.d_year = 2001
      AND d_cr.d_weekend = 'N'
      AND cp.cp_department = 'Electronics'
      AND r.r_reason_desc LIKE '%defective%'
)
SELECT
    s.s_store_id,
    w.w_warehouse_id,
    cp.cp_department,
    CASE WHEN r.r_reason_desc LIKE '%defective%' THEN 'Defective' ELSE 'Other' END AS reason_category,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(wr.wr_return_amt) AS max_web_return_amt
FROM filtered_cr cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_cr.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
JOIN household_demographics hd_refund_wr ON wr.wr_refunded_hdemo_sk = hd_refund_wr.hd_demo_sk
JOIN household_demographics hd_return_wr ON wr.wr_returning_hdemo_sk = hd_return_wr.hd_demo_sk
JOIN store_non_ca snc ON s.s_store_id = snc.s_store_id
WHERE s.s_store_id NOT IN (
        SELECT s3.s_store_id
        FROM store s3
        WHERE s3.s_city = 'Seattle'
    )
  AND s.s_gmt_offset > (
        SELECT MAX(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_state = 'CA'
    )
  AND inv.inv_quantity_on_hand > 0
  AND wr.wr_return_amt > 30
  AND t_cr.t_hour BETWEEN 9 AND 17
  AND t_wr.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_store_id,
    w.w_warehouse_id,
    cp.cp_department,
    CASE WHEN r.r_reason_desc LIKE '%defective%' THEN 'Defective' ELSE 'Other' END
ORDER BY total_catalog_net_loss DESC
LIMIT 100
