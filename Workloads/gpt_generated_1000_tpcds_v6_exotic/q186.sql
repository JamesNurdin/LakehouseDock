WITH
  /* Aggregate sales and returns per item */
  item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(cs.cs_net_paid) AS catalog_net_paid,
      SUM(ws.ws_net_paid) AS web_net_paid,
      SUM(sr.sr_return_amt) AS store_return_amt,
      COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
      COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM tpcds.item i
    LEFT JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY i.i_item_sk, i.i_item_id
  ),
  /* Pull distinct reasons once – used later */
  distinct_reasons AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM tpcds.reason
  )
SELECT
  i_sales.i_item_id,
  i.i_brand,
  i.i_category,
  i_sales.catalog_net_paid,
  i_sales.web_net_paid,
  i_sales.store_return_amt,
  (i_sales.catalog_net_paid + i_sales.web_net_paid) AS total_net_paid,
  hd_bill.hd_buy_potential,
  ib.ib_lower_bound,
  dr.r_reason_desc,
  ROW_NUMBER() OVER (ORDER BY (i_sales.catalog_net_paid + i_sales.web_net_paid) DESC) AS sales_rank,
  (
    SELECT AVG(inv.inv_quantity_on_hand)
    FROM tpcds.inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
  ) AS avg_inventory_on_hand
FROM item_sales i_sales
JOIN tpcds.item i ON i.i_item_sk = i_sales.i_item_sk
/* Join to a representative catalog sale to reach other dimensions */
LEFT JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN tpcds.household_demographics hd_bill ON hd_bill.hd_demo_sk = cs.cs_bill_hdemo_sk
LEFT JOIN tpcds.income_band ib ON ib.ib_income_band_sk = hd_bill.hd_income_band_sk
LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN distinct_reasons dr ON dr.r_reason_sk = cr.cr_reason_sk
LEFT JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN distinct_reasons sr_reason ON sr_reason.r_reason_sk = sr.sr_reason_sk
LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN distinct_reasons wr_reason ON wr_reason.r_reason_sk = wr.wr_reason_sk
LEFT JOIN tpcds.call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
LEFT JOIN tpcds.catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
LEFT JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN tpcds.time_dim td ON td.t_time_sk = cs.cs_sold_time_sk
WHERE i.i_color IN ('Red', 'Blue')
  AND sm.sm_code = 'AIR'
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'A'
  AND td.t_shift = 'first'
  AND td.t_hour BETWEEN 8 AND 12
  AND EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_item_sk = i.i_item_sk
      AND cr2.cr_return_quantity > 0
  )
GROUP BY
  i_sales.i_item_id,
  i.i_brand,
  i.i_category,
  i_sales.catalog_net_paid,
  i_sales.web_net_paid,
  i_sales.store_return_amt,
  hd_bill.hd_buy_potential,
  ib.ib_lower_bound,
  dr.r_reason_desc,
  i.i_item_sk
ORDER BY total_net_paid DESC
LIMIT 100
