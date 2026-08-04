WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
  ),
  common_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  base_agg AS (
    SELECT
      s.s_store_name,
      cp.cp_department,
      hd_sr.hd_buy_potential,
      ib.ib_lower_bound,
      COUNT(DISTINCT cs.cs_item_sk)                      AS distinct_items_sold,
      SUM(cs.cs_net_paid)                               AS total_net_paid,
      SUM(cr.cr_return_amount)                         AS total_return_amount,
      SUM(i.inv_quantity_on_hand)                      AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN common_orders co
      ON cs.cs_order_number = co.cs_order_number
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_cust
      ON c_bill.c_current_hdemo_sk = hd_cust.hd_demo_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w_cs
      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN warehouse w_cr
      ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN store_returns sr
      ON sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib
      ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
    JOIN sampled_inventory i
      ON i.inv_warehouse_sk = w_cs.w_warehouse_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs.cs_order_number
    )
    GROUP BY
      s.s_store_name,
      cp.cp_department,
      hd_sr.hd_buy_potential,
      ib.ib_lower_bound
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn,
  s_store_name,
  cp_department,
  hd_buy_potential,
  ib_lower_bound,
  distinct_items_sold,
  total_net_paid,
  total_return_amount,
  total_inventory_on_hand
FROM base_agg
ORDER BY total_net_paid DESC
LIMIT 100
