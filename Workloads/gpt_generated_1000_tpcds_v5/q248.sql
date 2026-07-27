/*
  Goal: Analyze sales performance per call center for the year 2001, comparing total catalog sales to returned amounts.
  The query joins all five selected tables using only the permitted join keys, applies six realistic filter predicates,
  aggregates key monetary measures, orders by total sales descending, and limits the output to the top 100 rows.
*/
SELECT
    cc.cc_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    AVG(cs.cs_net_profit) AS avg_profit,
    MIN(sr.sr_return_amt) AS min_return,
    MAX(cs.cs_ext_sales_price) AS max_sale
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer cu
  ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = cu.c_customer_sk
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_mkt_class LIKE '%Associated%'
  AND cu.c_preferred_cust_flag = 'Y'
  AND d_sales.d_year = 2001
  AND sr.sr_return_amt > 100
  AND cs.cs_ext_sales_price > 500
GROUP BY cc.cc_name, d_sales.d_year, d_sales.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
