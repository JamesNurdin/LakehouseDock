/*
  Goal: Analyze weekly sales performance for California stores in a specific quarter, 
  focusing on promo 1044, higher‑value transactions, and customers with a recent review.
*/
SELECT
  s.s_store_name,
  d.d_month_seq,
  t.t_hour,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  AVG(ss.ss_net_profit) AS avg_profit,
  COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
  MIN(ss.ss_ext_sales_price) AS min_sale,
  MAX(ss.ss_ext_sales_price) AS max_sale
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
WHERE ss.ss_promo_sk = 1044                                   -- promo filter
  AND ss.ss_ext_sales_price > 500.00                         -- high‑value sales
  AND ss.ss_quantity >= 2                                    -- at least 2 items per ticket
  AND d.d_week_seq = 5                                       -- specific week in quarter
  AND d.d_quarter_seq = 12                                   -- quarter 12 (e.g., Q4 FY)
  AND d.d_same_day_lq = 2414947                              -- matching last‑quarter day key
  AND s.s_state = 'CA'                                       -- California stores only
  AND t.t_hour BETWEEN 9 AND 17                              -- business hours
  AND c.c_last_review_date = 2452520                         -- customers with recent review
GROUP BY
  s.s_store_name,
  d.d_month_seq,
  t.t_hour
HAVING SUM(ss.ss_ext_sales_price) > 10000                     -- ensure meaningful aggregate
ORDER BY total_sales DESC
LIMIT 100
