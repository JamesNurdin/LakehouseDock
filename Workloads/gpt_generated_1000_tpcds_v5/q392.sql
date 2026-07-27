/* Goal: Analyze total sales, profit, returns and inventory by sales year and customer income band, showing subtotals for each year and overall total. */
WITH
  /* sales fact with year */
  sales_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d_sold.d_year AS sales_year
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
  ),
  /* inventory snapshot with the same date key as sales for joining */
  inventory_data AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      inv.inv_date_sk
    FROM inventory inv
    JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
  )
SELECT
  sd.sales_year,
  ib.ib_lower_bound AS income_lower,
  SUM(sd.ss_net_paid) AS total_sales_net_paid,
  SUM(sd.ss_net_profit) AS total_sales_profit,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
  SUM(COALESCE(id.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM sales_data sd
JOIN customer c
  ON sd.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sd.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN inventory_data id
  ON id.inv_date_sk = sd.ss_sold_date_sk
/* extra join to demonstrate reuse of date_dim for call_center open date */
LEFT JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY ROLLUP (sd.sales_year, ib.ib_lower_bound)
ORDER BY sd.sales_year, ib.ib_lower_bound
LIMIT 100
