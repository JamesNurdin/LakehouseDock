WITH
  sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_catalog_page_sk,
      cs.cs_net_paid_inc_tax,
      cs.cs_quantity,
      cs.cs_order_number
    FROM catalog_sales cs
  ),
  returns AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_refunded_cdemo_sk,
      wr.wr_web_page_sk,
      wr.wr_return_amt,
      wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
  )
SELECT
  d_sold.d_year,
  d_sold.d_month_seq,
  cp.cp_department,
  SUM(sales.cs_net_paid_inc_tax) AS total_sales,
  SUM(COALESCE(returns_sub.wr_return_amt, 0)) AS total_returns,
  COUNT(DISTINCT sales.cs_order_number) AS distinct_orders,
  CASE
    WHEN SUM(sales.cs_net_paid_inc_tax) > 100000 THEN 'HIGH'
    ELSE 'LOW'
  END AS sales_category,
  COALESCE(cd_bill.cd_gender, 'UNKNOWN') AS bill_gender,
  COALESCE(cd_ref.cd_gender, 'UNKNOWN') AS refund_gender
FROM
  sales
JOIN date_dim d_sold
  ON sales.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON sales.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_demographics cd_bill
  ON sales.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN catalog_page cp
  ON sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_refunded_cdemo_sk,
      wr.wr_web_page_sk,
      wr.wr_return_amt,
      wr.wr_order_number
    FROM returns wr
) returns_sub
  ON returns_sub.wr_returned_date_sk = d_sold.d_date_sk
JOIN date_dim d_ret
  ON returns_sub.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
  ON returns_sub.wr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_ref
  ON returns_sub.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN web_page wp
  ON returns_sub.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year = 2001
  AND t_sold.t_minute BETWEEN 0 AND 30
GROUP BY
  d_sold.d_year,
  d_sold.d_month_seq,
  cp.cp_department,
  cd_bill.cd_gender,
  cd_ref.cd_gender
HAVING SUM(sales.cs_net_paid_inc_tax) > 50000
ORDER BY total_sales DESC
LIMIT 100
