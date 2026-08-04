WITH
  sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sales_price,
      ss.ss_net_paid,
      ss.ss_store_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number
    FROM tpcds.store_sales ss
    WHERE ss.ss_sales_price > 20
      AND ss.ss_ext_tax < 100
      AND ss.ss_quantity >= 1
      AND ss.ss_net_paid IS NOT NULL
  ),
  addr AS (
    SELECT *
    FROM tpcds.customer_address ca
    WHERE ca.ca_state IN ('TX', 'NY', 'CA')
      AND ca.ca_city = 'Maple Grove'
  ),
  store_tbl AS (
    SELECT *
    FROM tpcds.store s
    WHERE s.s_state = 'TX'
  ),
  cat_ret AS (
    SELECT *
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_amount > 10
      AND cr.cr_fee > 0
  ),
  web_ret AS (
    SELECT *
    FROM tpcds.web_returns wr
    WHERE wr.wr_return_amt > 5
      AND wr.wr_fee > 0
  ),
  call_ctr AS (
    SELECT *
    FROM tpcds.call_center cc
    WHERE cc.cc_county = 'Maverick County'
  ),
  wh AS (
    SELECT *
    FROM tpcds.warehouse w
    WHERE w.w_gmt_offset = -6.00
  )
SELECT
  cc.cc_state               AS call_center_state,
  w.w_state                 AS warehouse_state,
  s.s_state                 AS store_state,
  ca.ca_state               AS customer_state,
  SUM(ss.ss_net_paid)      AS total_net_paid,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(wr.wr_return_amt)    AS total_web_return_amount,
  COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
  RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS revenue_rank,
  CASE
    WHEN SUM(ss.ss_net_paid) > 10000 THEN 'High'
    WHEN SUM(ss.ss_net_paid) > 5000  THEN 'Medium'
    ELSE 'Low'
  END AS revenue_category
FROM sales ss
JOIN addr ca       ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_tbl s    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN cat_ret cr ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN call_ctr cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
LEFT JOIN wh w       ON w.w_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN web_ret wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
GROUP BY CUBE (cc.cc_state, w.w_state, s.s_state, ca.ca_state)
HAVING SUM(ss.ss_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
