-- Goal: Summarize revenue and return performance by store and year, distinguishing profit direction, using deep joins across all TPC‑DS tables, with reused dimension aliases, a CASE expression, a scalar subquery, and an EXISTS filter.
WITH
  -- Alias date_dim for the sold date of catalog sales
  d_sold AS (
    SELECT * FROM date_dim
  ),
  -- Alias date_dim for the return date of catalog returns
  d_return AS (
    SELECT * FROM date_dim
  ),
  -- Alias date_dim for the sold date of store sales
  d_ss AS (
    SELECT * FROM date_dim
  ),
  -- Alias date_dim for the sold date of web sales
  d_ws_sold AS (
    SELECT * FROM date_dim
  )
SELECT
  s.s_store_name,
  d_sold.d_year,
  CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_indicator,
  SUM(cs.cs_net_paid) AS total_cs_net_paid,
  SUM(ss.ss_net_paid) AS total_ss_net_paid,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
  (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) AS avg_catalog_net_profit
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship
  ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN store_sales ss
  ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d_ss.d_date_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE EXISTS (
        SELECT 1
        FROM inventory inv_check
        WHERE inv_check.inv_warehouse_sk = w.w_warehouse_sk
          AND inv_check.inv_quantity_on_hand > 0
      )
GROUP BY
  s.s_store_name,
  d_sold.d_year,
  CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END
ORDER BY total_cs_net_paid DESC
