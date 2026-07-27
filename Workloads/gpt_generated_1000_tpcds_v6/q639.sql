/*
  Goal: Calculate per‑customer sales and return metrics, joining catalog sales, store sales, and web returns with demographic and address details. The query re‑uses dimension tables under different aliases, includes a LEFT OUTER JOIN to preserve customers without returns, and aggregates the results.
*/
SELECT
  c.c_customer_id,
  cd_bill.cd_gender,
  ca_bill.ca_state,
  cp.cp_department,
  SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
  SUM(ss.ss_ext_sales_price)               AS total_store_sales,
  SUM(COALESCE(wr.wr_return_amt, 0))        AS total_return_amount,
  COUNT(DISTINCT cs.cs_order_number)       AS distinct_catalog_orders,
  COUNT(DISTINCT ss.ss_ticket_number)      AS distinct_store_tickets
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk

JOIN store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca_store
  ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN customer_demographics cd_store
  ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store
  ON ss.ss_hdemo_sk = hd_store.hd_demo_sk

LEFT JOIN web_returns wr
  ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN customer_address ca_return_returning
  ON wr.wr_returning_addr_sk = ca_return_returning.ca_address_sk
JOIN customer_demographics cd_return_returning
  ON wr.wr_returning_cdemo_sk = cd_return_returning.cd_demo_sk
JOIN household_demographics hd_return_returning
  ON wr.wr_returning_hdemo_sk = hd_return_returning.hd_demo_sk
JOIN customer_address ca_return_refunded
  ON wr.wr_refunded_addr_sk = ca_return_refunded.ca_address_sk
JOIN customer_demographics cd_return_refunded
  ON wr.wr_refunded_cdemo_sk = cd_return_refunded.cd_demo_sk
JOIN household_demographics hd_return_refunded
  ON wr.wr_refunded_hdemo_sk = hd_return_refunded.hd_demo_sk

WHERE cp.cp_type = 'catalog'
GROUP BY
  c.c_customer_id,
  cd_bill.cd_gender,
  ca_bill.ca_state,
  cp.cp_department
ORDER BY total_catalog_sales DESC
LIMIT 100
