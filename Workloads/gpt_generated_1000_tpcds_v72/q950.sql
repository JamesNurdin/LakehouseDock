/*
Goal: Summarize catalog sales performance by profit flag, catalog department, and ship mode type for a specific set of catalog numbers, ship mode, and state, while only considering orders that had a return with the reason 'Customer Not Interested'. The query joins all seven TPC‑DS tables, applies multiple realistic filters, uses a CASE expression, aggregates key metrics, and limits the output to the top 100 rows.
*/
SELECT
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  cp.cp_department,
  sm.sm_type,
  SUM(cs.cs_net_paid_inc_tax)            AS total_sales,
  SUM(cs.cs_quantity)                    AS total_quantity,
  AVG(cs.cs_ext_discount_amt)            AS avg_discount,
  COUNT(DISTINCT cs.cs_order_number)     AS distinct_orders
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cp.cp_catalog_number IN (5, 12)
  AND sm.sm_code = 'AIR'
  AND cc.cc_state = 'CA'
  AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
          AND r.r_reason_desc = 'Customer Not Interested'
      )
GROUP BY
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
  cp.cp_department,
  sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
