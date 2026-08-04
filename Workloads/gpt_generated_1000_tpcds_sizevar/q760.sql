WITH base_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_wholesale_cost,
    cs.cs_quantity,
    cs.cs_sold_date_sk,
    hd_bill.hd_dep_count               AS bill_dep_count,
    hd_ship.hd_dep_count               AS ship_dep_count,
    cc1.cc_name                         AS call_center_name,
    cc2.cc_manager                      AS call_center_manager,
    p.p_promo_name                      AS p_promo_name,
    td.t_sub_shift                      AS sold_sub_shift,
    td.t_time                           AS sold_time
  FROM catalog_sales cs
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN call_center cc1
    ON cs.cs_call_center_sk = cc1.cc_call_center_sk
  JOIN call_center cc2
    ON cs.cs_call_center_sk = cc2.cc_call_center_sk
  JOIN call_center cc3
    ON cs.cs_call_center_sk = cc3.cc_call_center_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN promotion p2
    ON cs.cs_promo_sk = p2.p_promo_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN time_dim td_dup
    ON cs.cs_sold_time_sk = td_dup.t_time_sk
  JOIN time_dim td_extra
    ON cs.cs_sold_time_sk = td_extra.t_time_sk
)
SELECT
  call_center_name,
  call_center_manager,
  p_promo_name,
  sold_sub_shift,
  CASE WHEN SUM(cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
  SUM(cs_net_profit)                         AS total_net_profit,
  COUNT(*)                                   AS order_cnt
FROM base_sales
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_sales cs2
  WHERE cs2.cs_order_number = base_sales.cs_order_number
    AND cs2.cs_net_profit > 10000
)
  AND base_sales.cs_order_number IN (
    SELECT cs3.cs_order_number FROM catalog_sales cs3 WHERE cs3.cs_quantity > 5
    INTERSECT
    SELECT cs4.cs_order_number FROM catalog_sales cs4 WHERE cs4.cs_wholesale_cost < 30
  )
GROUP BY GROUPING SETS (
  (call_center_name, p_promo_name, sold_sub_shift),
  (call_center_manager, sold_sub_shift),
  ()
)
ORDER BY total_net_profit DESC, order_cnt DESC
OFFSET 0 LIMIT 100
