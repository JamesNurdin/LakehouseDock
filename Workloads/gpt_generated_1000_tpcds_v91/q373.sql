SELECT
  cp.cp_department,
  i.i_brand,
  SUM(cs.cs_net_paid_inc_tax) AS total_sales,
  AVG(cs.cs_net_profit) AS avg_profit,
  COUNT(DISTINCT cs.cs_order_number) AS num_orders,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  MIN(p.p_cost) AS min_promo_cost,
  MAX(p.p_cost) AS max_promo_cost,
  top_promo.p_promo_name,
  top_promo.p_cost,
  (SELECT SUM(cs_all.cs_net_paid_inc_tax) FROM catalog_sales cs_all) AS grand_total_sales
FROM
  catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
  JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
  JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  JOIN catalog_page cp_ret
    ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
  CROSS JOIN LATERAL (
    SELECT p2.p_promo_name, p2.p_cost
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
    ORDER BY p2.p_cost DESC
    LIMIT 1
  ) AS top_promo
WHERE
  d_sold.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
  AND ca_bill.ca_county = 'York County'
  AND i.i_manager_id = 21
  AND ib.ib_lower_bound >= 50001
  AND p.p_discount_active = 'Y'
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
      AND cr2.cr_return_quantity > 0
  )
GROUP BY
  ROLLUP(cp.cp_department, i.i_brand, top_promo.p_promo_name, top_promo.p_cost)
HAVING
  SUM(cs.cs_net_paid_inc_tax) > 1000000
  AND COUNT(DISTINCT cs.cs_order_number) >= 10
ORDER BY
  total_sales DESC,
  cp.cp_department,
  i.i_brand
