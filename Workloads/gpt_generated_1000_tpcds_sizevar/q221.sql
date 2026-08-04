WITH
  customers_sales AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  ),
  customers_web_returns AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  ),
  filtered_customers AS (
    SELECT c_customer_id FROM customers_sales
    EXCEPT
    SELECT c_customer_id FROM customers_web_returns
  ),
  agg AS (
    SELECT
      d.d_year,
      s.s_store_name,
      i.i_brand,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(sr.sr_return_amt) AS total_return_amount,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(sr.sr_store_credit) AS total_store_credit,
      COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk AND wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_color = 'Red'
      AND c.c_customer_id IN (SELECT c_customer_id FROM filtered_customers)
    GROUP BY d.d_year, s.s_store_name, i.i_brand
  )
SELECT
  d_year,
  s_store_name,
  i_brand,
  total_sales,
  total_return_amount,
  total_profit,
  distinct_customers,
  CASE WHEN total_store_credit > 1000 THEN 'High Credit' ELSE 'Low Credit' END AS credit_category
FROM agg
ORDER BY total_sales DESC
LIMIT 100
