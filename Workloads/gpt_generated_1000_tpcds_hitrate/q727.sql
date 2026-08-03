WITH
  date_dim_filtered AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_year = 2001
  ),
  store_sales_enhanced AS (
    SELECT ss.ss_ticket_number,
           ss.ss_sold_date_sk,
           ss.ss_store_sk,
           ss.ss_item_sk,
           ss.ss_net_paid_inc_tax,
           ss.ss_ext_discount_amt,
           s.s_store_name,
           s.s_division_name,
           d.d_month_seq,
           p.p_discount_active,
           CASE WHEN ss.ss_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_level
    FROM store_sales ss
    JOIN date_dim_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  ),
  store_returns_enhanced AS (
    SELECT sr.sr_ticket_number,
           sr.sr_return_amt,
           sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
  ),
  store_full AS (
    SELECT ss.*, 
           COALESCE(sr.sr_return_amt, 0)     AS return_amount,
           COALESCE(sr.sr_net_loss, 0)      AS return_loss
    FROM store_sales_enhanced ss
    LEFT JOIN store_returns_enhanced sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
  ),
  web_sales_enhanced AS (
    SELECT ws.ws_order_number,
           ws.ws_sold_date_sk,
           ws.ws_ship_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid,
           ws.ws_ext_discount_amt,
           ws.ws_quantity,
           ws.ws_warehouse_sk,
           w.w_warehouse_name,
           sm.sm_type                     AS ship_type,
           ws.ws_promo_sk,
           p.p_discount_active,
           ca_bill.ca_city                AS bill_city,
           ca_ship.ca_city                AS ship_city,
           d.d_month_seq,
           CASE WHEN ws.ws_ext_discount_amt > 50 THEN 'High' ELSE 'Low' END AS discount_level
    FROM web_sales ws
    JOIN date_dim_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  ),
  web_returns_enhanced AS (
    SELECT wr.wr_order_number,
           wr.wr_return_amt,
           wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
  ),
  web_full AS (
    SELECT ws.*, 
           COALESCE(wr.wr_return_amt, 0) AS return_amount,
           COALESCE(wr.wr_net_loss, 0)  AS return_loss
    FROM web_sales_enhanced ws
    LEFT JOIN web_returns_enhanced wr
      ON ws.ws_order_number = wr.wr_order_number
  ),
  inventory_agg AS (
    SELECT i.inv_warehouse_sk,
           i.inv_quantity_on_hand,
           d.d_month_seq,
           w.w_warehouse_name
    FROM inventory i
    JOIN date_dim_filtered d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
  ),
  call_center_agg AS (
    SELECT cc.cc_call_center_id,
           d.d_month_seq,
           cc.cc_name
    FROM call_center cc
    JOIN date_dim_filtered d ON cc.cc_closed_date_sk = d.d_date_sk
  ),
  catalog_page_agg AS (
    SELECT cp.cp_catalog_page_id,
           d.d_month_seq,
           cp.cp_department
    FROM catalog_page cp
    JOIN date_dim_filtered d ON cp.cp_end_date_sk = d.d_date_sk
  ),
  combined AS (
    SELECT
      COALESCE(sf.ss_ticket_number, wf.ws_order_number)          AS transaction_id,
      COALESCE(sf.s_store_name, wf.w_warehouse_name)            AS location_name,
      COALESCE(sf.s_division_name, 'Web')                      AS division,
      COALESCE(sf.d_month_seq, wf.d_month_seq)                AS month_seq,
      COALESCE(sf.ss_net_paid_inc_tax, 0) - COALESCE(sf.return_amount, 0) AS net_store_sales,
      COALESCE(wf.ws_net_paid, 0) - COALESCE(wf.return_amount, 0)           AS net_web_sales,
      COALESCE(i.inv_quantity_on_hand, 0)                               AS inventory_qty
    FROM store_full sf
    FULL OUTER JOIN web_full wf
      ON sf.d_month_seq = wf.d_month_seq
    LEFT JOIN inventory_agg i
      ON i.d_month_seq = COALESCE(sf.d_month_seq, wf.d_month_seq)
  )
SELECT
  division,
  month_seq,
  SUM(net_store_sales) AS total_store_sales,
  SUM(net_web_sales)   AS total_web_sales,
  SUM(inventory_qty)   AS total_inventory,
  ROW_NUMBER() OVER (PARTITION BY division ORDER BY SUM(net_store_sales) DESC) AS sales_rank,
  (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y')               AS active_promo_count,
  CASE
    WHEN SUM(net_store_sales) + SUM(net_web_sales) > 100000 THEN 'High Volume'
    ELSE 'Normal Volume'
  END AS volume_category
FROM combined
GROUP BY ROLLUP (division, month_seq)
ORDER BY division, month_seq
LIMIT 100
