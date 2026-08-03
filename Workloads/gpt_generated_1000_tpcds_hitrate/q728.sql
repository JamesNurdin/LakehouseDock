WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        -- Running total of sales price per call center ordered by the surrogate sold‑date key
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY cs.cs_call_center_sk 
            ORDER BY cs.cs_sold_date_sk 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales_by_cc
    FROM catalog_sales cs
)
SELECT
    cc.cc_division,
    cp.cp_department,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN SUM(sa.cs_ext_sales_price) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS sales_category,
    SUM(sa.cs_quantity)               AS total_quantity,
    SUM(sa.cs_ext_sales_price)        AS total_sales,
    SUM(sa.cs_net_profit)             AS total_profit,
    COUNT(DISTINCT sa.cs_order_number) AS unique_orders,
    MAX(sa.running_sales_by_cc)       AS max_running_sales_by_cc
FROM sales_agg sa
JOIN call_center cc
  ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_bill
  ON sa.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON sa.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = sa.cs_order_number
JOIN call_center cc_ret
  ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
JOIN catalog_page cp_ret
  ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sa.cs_order_number
      AND cr2.cr_return_amount > 0
)
GROUP BY GROUPING SETS (
    (cc.cc_division, cp.cp_department, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound),
    (cc.cc_division, cp.cp_department)
)
HAVING SUM(sa.cs_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
