WITH sales_by_center_warehouse AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_code,
        ib.ib_income_band_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 0
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm2
          WHERE sm2.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm2.sm_contract = 'qENFQ'
      )
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_id,
        w.w_warehouse_name,
        sm.sm_code,
        ib.ib_income_band_sk
),
aggregated_center AS (
    SELECT
        cc_call_center_id,
        cc_name,
        SUM(total_sales) AS center_total_sales,
        SUM(orders) AS center_orders,
        AVG(avg_quantity) AS center_avg_quantity
    FROM sales_by_center_warehouse
    GROUP BY cc_call_center_id, cc_name
    HAVING SUM(total_sales) > 500000
)
SELECT
    cc_call_center_id,
    cc_name,
    center_total_sales,
    center_orders,
    center_avg_quantity,
    center_total_sales / center_orders AS avg_sales_per_order
FROM aggregated_center
WHERE center_avg_quantity > 10
ORDER BY center_total_sales DESC
LIMIT 100
