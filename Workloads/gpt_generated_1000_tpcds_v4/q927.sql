/*
Goal: Summarize net paid amounts and other sales metrics per call‑center manager and ship‑mode for high‑value transactions, applying multiple realistic filter predicates.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_wholesale_cost,
        cs.cs_quantity,
        cs.cs_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship_tax > 2000
      AND cs.cs_wholesale_cost BETWEEN 20 AND 50
      AND cs.cs_quantity >= 5
      AND cs.cs_sold_date_sk = 2452
)
SELECT
    cc.cc_manager,
    cc.cc_suite_number,
    sm.sm_carrier,
    sm.sm_code,
    SUM(fs.cs_net_paid_inc_ship_tax)          AS total_net_paid_inc_ship_tax,
    AVG(fs.cs_wholesale_cost)                 AS avg_wholesale_cost,
    COUNT(DISTINCT fs.cs_order_number)        AS distinct_orders,
    MIN(fs.cs_quantity)                       AS min_quantity,
    MAX(fs.cs_sales_price)                    AS max_sales_price
FROM filtered_sales fs
JOIN call_center cc
  ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cc.cc_manager = 'Larry Mccray'
  AND cc.cc_suite_number = 'Suite 310'
  AND sm.sm_contract = 'YvxVaJI10'
  AND sm.sm_code = 'AIR'
  AND sm.sm_carrier = 'UPS'
  AND cc.cc_gmt_offset = -5.00
GROUP BY
    cc.cc_manager,
    cc.cc_suite_number,
    sm.sm_carrier,
    sm.sm_code
ORDER BY total_net_paid_inc_ship_tax DESC
LIMIT 100
