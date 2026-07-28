WITH store_branch AS (
   SELECT
       'Store' AS sales_channel,
       d.d_year AS year,
       d.d_month_seq AS month,
       i.i_category AS category,
       SUM(ss.ss_ext_sales_price) AS total_sales_amount,
       SUM(ss.ss_quantity) AS total_quantity
   FROM tpcds.store_sales ss
   JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
   JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN tpcds.customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
   JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
   JOIN tpcds.warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
   JOIN tpcds.call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   GROUP BY ROLLUP (d.d_year, d.d_month_seq, i.i_category)
),
web_branch AS (
   SELECT
       'Web' AS sales_channel,
       d.d_year AS year,
       d.d_month_seq AS month,
       i.i_category AS category,
       SUM(ws.ws_ext_sales_price) AS total_sales_amount,
       SUM(ws.ws_quantity) AS total_quantity
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.web_site web ON ws.ws_web_site_sk = web.web_site_sk
   JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN tpcds.customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   LEFT JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
   LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN tpcds.call_center cc2 ON cc2.cc_open_date_sk = d.d_date_sk
   LEFT JOIN tpcds.catalog_page cp2 ON cp2.cp_end_date_sk = d.d_date_sk
   GROUP BY ROLLUP (d.d_year, d.d_month_seq, i.i_category)
)
SELECT
   sales_channel,
   year,
   month,
   category,
   total_sales_amount,
   total_quantity,
   ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_sales_amount DESC) AS rn
FROM (
   SELECT * FROM store_branch
   UNION ALL
   SELECT * FROM web_branch
) AS combined
ORDER BY sales_channel, year, month, category
LIMIT 100
