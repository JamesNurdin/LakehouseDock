SELECT
    s.s_store_name,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    COUNT(wr.wr_return_quantity) AS return_transactions
FROM tpcds.store_sales ss
JOIN tpcds.date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND c.c_preferred_cust_flag = 'Y'
  AND s.s_floor_space > 7000000
  AND wr.wr_return_quantity > 5
GROUP BY s.s_store_name, d.d_year
ORDER BY total_sales DESC
LIMIT 100
