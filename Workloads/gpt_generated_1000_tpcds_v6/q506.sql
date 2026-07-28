SELECT
  w.w_state,
  cd_ret.cd_gender,
  COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cs.cs_net_paid) AS avg_net_paid,
  SUM(CASE WHEN cr.cr_return_tax > 20 THEN cr.cr_return_tax ELSE 0 END) AS high_tax_return_sum,
  MIN(cr.cr_return_ship_cost) AS min_ship_cost,
  MAX(cr.cr_return_ship_cost) AS max_ship_cost
FROM
  catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE
  w.w_country = 'United States'
  AND w.w_suite_number LIKE 'Suite %'
  AND cd_ref.cd_gender = 'F'
  AND cd_ref.cd_education_status = 'College'
  AND cr.cr_return_tax > 10
  AND cr.cr_return_ship_cost BETWEEN 100 AND 1300
  AND cs.cs_quantity >= 2
  AND p.p_discount_active = 'Y'
GROUP BY ROLLUP (w.w_state, cd_ret.cd_gender)
ORDER BY w.w_state, cd_ret.cd_gender NULLS LAST
