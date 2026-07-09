SELECT
  cp.cp_department,
  cp.cp_type,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
  SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
  AVG(wr.wr_return_quantity) AS avg_return_qty,
  SUM(wr.wr_fee) AS total_fee,
  RANK() OVER (ORDER BY SUM(wr.wr_return_amt_inc_tax) DESC) AS revenue_rank
FROM catalog_page cp
JOIN web_returns wr
  ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
WHERE cp.cp_catalog_page_number IN (1, 2, 3)
  AND cp.cp_department IS NOT NULL
GROUP BY cp.cp_department, cp.cp_type
HAVING SUM(wr.wr_return_amt_inc_tax) > 1000
ORDER BY total_return_amount DESC
LIMIT 50
