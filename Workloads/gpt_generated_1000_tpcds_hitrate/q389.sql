WITH
  sales_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_date_sk,
      ws_warehouse_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      ws_bill_addr_sk,
      ws_ship_customer_sk,
      ws_ship_cdemo_sk,
      ws_ship_hdemo_sk,
      ws_ship_addr_sk,
      ws_order_number,
      SUM(ws_ext_sales_price)   AS total_sales,
      SUM(ws_quantity)          AS total_qty,
      SUM(ws_net_profit)        AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk IS NOT NULL
    GROUP BY
      ws_item_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_date_sk,
      ws_warehouse_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      ws_bill_customer_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      ws_bill_addr_sk,
      ws_ship_customer_sk,
      ws_ship_cdemo_sk,
      ws_ship_hdemo_sk,
      ws_ship_addr_sk,
      ws_order_number
  ),
  returns_full AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_reason_sk          AS cr_reason_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_warehouse_sk,
      wr.wr_item_sk            AS wr_item_sk,
      wr.wr_returned_date_sk   AS wr_returned_date_sk,
      wr.wr_return_quantity    AS wr_quantity,
      wr.wr_return_amt         AS wr_amount,
      wr.wr_reason_sk          AS wr_reason_sk
    FROM catalog_returns cr
    FULL OUTER JOIN web_returns wr
      ON cr.cr_item_sk = wr.wr_item_sk
     AND cr.cr_returned_date_sk = wr.wr_returned_date_sk
  )
SELECT
  d_sold.d_year,
  i.i_category,
  cc.cc_name,
  cp.cp_type,
  COALESCE(r_cr.r_reason_desc, r_wr.r_reason_desc) AS return_reason,
  w.w_warehouse_name,
  wp.wp_type,
  ws.web_name,
  SUM(sa.total_sales)      AS agg_sales,
  SUM(sa.total_profit)     AS agg_profit,
  CASE WHEN SUM(sa.total_sales) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
  (SELECT AVG(i_current_price) FROM item) AS avg_item_price,
  ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(sa.total_sales) DESC) AS rn
FROM sales_agg sa
JOIN item i
  ON sa.ws_item_sk = i.i_item_sk
JOIN date_dim d_sold
  ON sa.ws_sold_date_sk = d_sold.d_date_sk
LEFT JOIN time_dim t_sold
  ON sa.ws_sold_time_sk = t_sold.t_time_sk
JOIN warehouse w
  ON sa.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON sa.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
  ON sa.ws_web_site_sk = ws.web_site_sk
JOIN customer c_bill
  ON sa.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON sa.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
  ON sa.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON sa.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
  ON sa.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
  ON sa.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_ship
  ON sa.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON sa.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN returns_full rf
  ON rf.cr_item_sk = i.i_item_sk
 AND rf.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN reason r_cr
  ON rf.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN reason r_wr
  ON rf.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN call_center cc
  ON rf.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
  ON rf.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w_ret
  ON rf.cr_warehouse_sk = w_ret.w_warehouse_sk
LEFT JOIN date_dim d_return
  ON rf.cr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
GROUP BY
  d_sold.d_year,
  i.i_category,
  cc.cc_name,
  cp.cp_type,
  COALESCE(r_cr.r_reason_desc, r_wr.r_reason_desc),
  w.w_warehouse_name,
  wp.wp_type,
  ws.web_name
ORDER BY agg_sales DESC
LIMIT 100
