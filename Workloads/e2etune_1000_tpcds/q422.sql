SELECT
  s.s_state,
  s.s_city,
  SUM(ss.ss_net_paid) AS total_sales,
  COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
  AVG(ss.ss_sales_price) AS avg_sales_price,
  (
    SELECT SUM(wr.wr_return_amt)
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE CONCAT('%', s.s_state, '%')
      AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
  ) AS total_returns_for_state
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY s.s_state, s.s_city
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
