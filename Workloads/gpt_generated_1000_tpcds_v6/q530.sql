WITH sales_summary AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        SUM(cs.cs_ext_sales_price)                      AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0))           AS total_returns,
        COUNT(DISTINCT cs.cs_order_number)              AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_code = 'AIR'
      AND cp.cp_type = 'monthly'
    GROUP BY cc.cc_call_center_id, cp.cp_catalog_page_id
)
SELECT
    ss.cc_call_center_id,
    ss.cp_catalog_page_id,
    ss.total_sales,
    ss.total_returns,
    (ss.total_sales - ss.total_returns)                               AS net_sales,
    CASE WHEN ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
         THEN 'Above Avg'
         ELSE 'Below Avg'
    END                                                               AS sales_category
FROM sales_summary ss
WHERE (ss.total_sales - ss.total_returns) > 0
ORDER BY net_sales DESC
LIMIT 100
