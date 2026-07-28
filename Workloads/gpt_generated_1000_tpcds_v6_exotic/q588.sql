/*
  Goal: Analyze net revenue by promotion name, ship mode type, and warehouse city, combining catalog sales, returns, store sales and web page activity, and keep only promotions with total sales exceeding 100,000.
*/
WITH
  cs AS (
    SELECT *
    FROM catalog_sales
  ),
  cr AS (
    SELECT *
    FROM catalog_returns
  )
SELECT
  promo_sales.p_promo_name,
  sm_sales.sm_type AS ship_mode_type,
  wh_sales.w_city AS warehouse_city,
  COUNT(DISTINCT cs.cs_order_number) AS orders_sold,
  SUM(cs.cs_net_paid) AS total_sales,
  SUM(cr.cr_return_amount) AS total_returns,
  (SUM(cs.cs_net_paid) - SUM(cr.cr_return_amount)) AS net_revenue
FROM cs
JOIN customer AS cust_bill
  ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer AS cust_ship
  ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN ship_mode AS sm_sales
  ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN warehouse AS wh_sales
  ON cs.cs_warehouse_sk = wh_sales.w_warehouse_sk
JOIN promotion AS promo_sales
  ON cs.cs_promo_sk = promo_sales.p_promo_sk
JOIN cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN ship_mode AS sm_return
  ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
JOIN warehouse AS wh_return
  ON cr.cr_warehouse_sk = wh_return.w_warehouse_sk
JOIN customer AS cust_refund
  ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
JOIN store_sales AS ss
  ON ss.ss_customer_sk = cust_bill.c_customer_sk
JOIN promotion AS promo_store
  ON ss.ss_promo_sk = promo_store.p_promo_sk
JOIN web_page AS wp
  ON wp.wp_customer_sk = cust_bill.c_customer_sk
GROUP BY
  promo_sales.p_promo_name,
  sm_sales.sm_type,
  wh_sales.w_city
HAVING
  SUM(cs.cs_net_paid) > 100000
ORDER BY
  net_revenue DESC
LIMIT 100
