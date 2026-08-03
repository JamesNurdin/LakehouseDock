WITH sales_returns AS (
   SELECT
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_net_paid_inc_tax,
       cs.cs_quantity,
       cs.cs_ext_list_price,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_reason_sk,
       cr.cr_ship_mode_sk,
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_vehicle_count,
       sm.sm_type,
       sm.sm_carrier,
       r.r_reason_desc
   FROM catalog_sales cs
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE cs.cs_net_paid_inc_tax > 5000
     AND cs.cs_quantity BETWEEN 1 AND 10
     AND cr.cr_return_amount > 100
     AND hd.hd_income_band_sk IN (1, 2, 3)
     AND sm.sm_type = 'AIR'
)
SELECT
    sr.hd_demo_sk,
    sr.hd_income_band_sk,
    sr.sm_type,
    sr.r_reason_desc,
    COUNT(DISTINCT sr.cs_item_sk) AS distinct_items_sold,
    SUM(sr.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(sr.cr_return_amount) AS avg_return_amount,
    MIN(sr.cs_ext_list_price) AS min_list_price,
    MAX(sr.cs_ext_list_price) AS max_list_price,
    CASE
        WHEN SUM(sr.cr_return_amount) > 10000 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM sales_returns sr
JOIN store_sales ss
  ON ss.ss_hdemo_sk = sr.hd_demo_sk
WHERE ss.ss_ext_discount_amt < 500
  AND ss.ss_item_sk IN (
        SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 5
    )
GROUP BY
    sr.hd_demo_sk,
    sr.hd_income_band_sk,
    sr.sm_type,
    sr.r_reason_desc
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
