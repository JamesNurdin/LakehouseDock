/*
 Goal: Summarize web sales and return performance by web site, sales year, return reason, call center, catalog department, and income band, showing total net paid, total sales, total returns, net loss, distinct orders, average vehicle count, and the overall maximum income band upper bound.
*/
SELECT
  ws_site.web_name                     AS web_site_name,
  d_sold.d_year                        AS sales_year,
  r.r_reason_desc                      AS return_reason,
  cc.cc_name                           AS call_center_name,
  cp.cp_department                     AS catalog_department,
  ib.ib_lower_bound                    AS income_lower_bound,
  ib.ib_upper_bound                    AS income_upper_bound,
  SUM(ws.ws_net_paid)                 AS total_net_paid,
  SUM(ws.ws_ext_sales_price)          AS total_ext_sales,
  SUM(wr.wr_return_amt)               AS total_return_amount,
  SUM(wr.wr_net_loss)                 AS total_net_loss,
  COUNT(DISTINCT ws.ws_order_number)  AS distinct_orders,
  AVG(hd_bill.hd_vehicle_count)       AS avg_vehicle_count,
  (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper
FROM
  web_sales ws
  /* Date dimension for the sold date (also reused for other roles) */
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  /* Date dimension for the ship date */
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  /* Billing customer */
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  /* Billing household demographics */
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  /* Shipping customer */
  JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  /* Shipping household demographics */
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  /* Web site */
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  /* Returns for the same order/item */
  JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                         AND ws.ws_item_sk = wr.wr_item_sk
  /* Return date */
  JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
  /* Reason for the return */
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  /* Refunded customer */
  JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
  /* Refunded household */
  JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  /* Returning customer */
  JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
  /* Returning household */
  JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
  /* Income band for billing household */
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  /* Call center (closed date linked to sold date) */
  JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
  /* Catalog page (start date linked to sold date) */
  JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE
  d_sold.d_year = 2001
GROUP BY
  ws_site.web_name,
  d_sold.d_year,
  r.r_reason_desc,
  cc.cc_name,
  cp.cp_department,
  ib.ib_lower_bound,
  ib.ib_upper_bound
ORDER BY
  total_net_paid DESC
LIMIT 100
