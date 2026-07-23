/*
  Goal: Analyze total sales and return performance by catalog department, year, and shipping type across all sales channels (catalog, store, web) while accounting for returns.
*/
SELECT
    cp.cp_department AS department,
    d_sold.d_year      AS year,
    sm.sm_type         AS ship_type,
    SUM(cs.cs_ext_sales_price)   AS total_catalog_sales,
    SUM(cs.cs_net_profit)        AS catalog_net_profit,
    SUM(ss.ss_ext_sales_price)   AS total_store_sales,
    SUM(ss.ss_net_profit)        AS store_net_profit,
    SUM(ws.ws_ext_sales_price)   AS total_web_sales,
    SUM(ws.ws_net_profit)        AS web_net_profit,
    SUM(cr.cr_return_amount)     AS total_return_amount,
    SUM(cr.cr_net_loss)          AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w_sales
  ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN warehouse w_ret
  ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
GROUP BY cp.cp_department, d_sold.d_year, sm.sm_type
HAVING SUM(cs.cs_ext_sales_price) > 100000
ORDER BY total_catalog_sales DESC
LIMIT 100
