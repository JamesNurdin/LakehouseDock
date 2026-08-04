/*
  Goal: Summarize catalog sales and returns by store and year, showing profit category, total net paid, total profit, order count, return quantity and distinct return reasons. The query joins all 16 selected tables, re‑uses several tables with different aliases, includes a RIGHT OUTER JOIN between catalog_returns (fact) and reason (dimension) to retain all reasons, uses a CASE expression, groups and orders the result, and limits to the top 100 rows.
*/
WITH
  -- Join catalog_returns to reason with a RIGHT OUTER JOIN so every reason is kept
  returns_reason AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_reason_sk,
      r.r_reason_desc
    FROM catalog_returns cr
    RIGHT OUTER JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
  )
SELECT
  s.s_store_id,
  s.s_store_name,
  d_sold.d_year,
  CASE
    WHEN cs.cs_net_profit > 0 THEN 'Profitable'
    ELSE 'Loss'
  END AS profit_category,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
  SUM(COALESCE(rr.cr_return_quantity, 0)) AS total_return_qty,
  COUNT(DISTINCT rr.r_reason_desc) AS distinct_return_reasons
FROM catalog_sales cs
  -- left‑join the returns (with reasons) to the sales fact
  LEFT JOIN returns_reason rr
    ON cs.cs_order_number = rr.cr_order_number
  -- date dimensions for sold and shipped dates
  LEFT JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
  -- item dimension
  LEFT JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  -- call‑center dimension
  LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  -- catalog page dimension
  LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  -- ship‑mode dimension
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  -- warehouse dimension
  LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  -- customer dimensions (billing and shipping)
  LEFT JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  LEFT JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  -- household‑demographics dimensions (billing and shipping)
  LEFT JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  -- customer‑address dimensions (billing and shipping)
  LEFT JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  LEFT JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  -- income‑band (via billing household demographics)
  LEFT JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  -- store dimension (joined through the sold‑date dim)
  LEFT JOIN store s
    ON d_sold.d_date_sk = s.s_closed_date_sk
  -- inventory (item‑warehouse‑date bridge)
  LEFT JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
   AND w.w_warehouse_sk = inv.inv_warehouse_sk
   AND d_sold.d_date_sk = inv.inv_date_sk
  -- web page (linked to billing customer and sold‑date)
  LEFT JOIN web_page wp
    ON c_bill.c_customer_sk = wp.wp_customer_sk
   AND d_sold.d_date_sk = wp.wp_creation_date_sk
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d_sold.d_year,
  CASE
    WHEN cs.cs_net_profit > 0 THEN 'Profitable'
    ELSE 'Loss'
  END
ORDER BY
  total_net_paid DESC
LIMIT 100
