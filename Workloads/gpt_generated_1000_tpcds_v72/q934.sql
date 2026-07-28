WITH
  joined AS (
    SELECT
      d_sold.d_year                                     AS d_year,
      i.i_category                                     AS i_category,
      s.s_state                                        AS store_state,
      cs.cs_ext_sales_price                           AS catalog_sales_amount,
      ws.ws_ext_sales_price                           AS web_sales_amount,
      wr.wr_return_amt                                AS return_amount,
      inv.inv_quantity_on_hand                        AS inventory_qty,
      cs.cs_bill_customer_sk                          AS customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    /* join web_sales directly to the same dimension tables */
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d_sold.d_date_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store s
      ON s.s_closed_date_sk = d_ship.d_date_sk
    /* additional date joins for call_center and catalog_page (optional) */
    LEFT JOIN date_dim d_cc_open
      ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    LEFT JOIN date_dim d_cc_closed
      ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN date_dim d_cp_start
      ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
      ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND w.w_state = 'CA'
      AND cc.cc_state = 'TX'
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
  )
SELECT
  d_year,
  i_category,
  store_state,
  SUM(catalog_sales_amount)          AS total_catalog_sales,
  SUM(web_sales_amount)              AS total_web_sales,
  SUM(return_amount)                 AS total_returns,
  SUM(inventory_qty)                 AS total_inventory,
  COUNT(DISTINCT customer_sk)        AS distinct_customers,
  SUM(catalog_sales_amount) / NULLIF(
    (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales),
    0
  )                                   AS sales_discount_ratio,
  RANK() OVER (ORDER BY SUM(catalog_sales_amount) DESC) AS sales_rank
FROM joined
GROUP BY ROLLUP (d_year, i_category, store_state)
ORDER BY d_year, i_category, store_state
LIMIT 100
