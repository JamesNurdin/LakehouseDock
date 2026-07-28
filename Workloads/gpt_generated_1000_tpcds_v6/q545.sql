WITH
  sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      ss.ss_sold_date_sk,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales,
      COUNT(*) AS sales_cnt,
      AVG(ss.ss_ext_wholesale_cost) AS avg_wholesale_cost,
      MIN(t.t_hour) AS min_hour,
      MAX(t.t_hour) AS max_hour
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_ext_wholesale_cost > 500
      AND t.t_minute IN (7, 10, 17, 18)
      AND t.t_second BETWEEN 9 AND 15
    GROUP BY ss.ss_customer_sk, ss.ss_sold_date_sk
  ),
  returns_agg AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_returned_date_sk,
      SUM(sr.sr_net_loss) AS total_loss,
      COUNT(*) AS return_cnt,
      MIN(t.t_hour) AS ret_min_hour,
      MAX(t.t_hour) AS ret_max_hour
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 100
      AND r.r_reason_desc NOT LIKE '%Damaged%'
      AND t.t_hour BETWEEN 6 AND 12
    GROUP BY sr.sr_customer_sk, sr.sr_returned_date_sk
  ),
  high_sales AS (
    SELECT ss_customer_sk AS cust_sk, total_sales
    FROM sales_agg
    WHERE total_sales > 5000
  ),
  high_returns AS (
    SELECT sr_customer_sk AS cust_sk, total_loss
    FROM returns_agg
    WHERE total_loss > 2000
  ),
  target_customers AS (
    SELECT cust_sk, total_sales AS metric, 'sales' AS src FROM high_sales
    UNION
    SELECT cust_sk, total_loss AS metric, 'returns' AS src FROM high_returns
  )
SELECT
  c.c_customer_id,
  ca.ca_city,
  ca.ca_state,
  tc.metric,
  tc.src,
  s.total_sales,
  r.total_loss,
  (s.total_sales - r.total_loss) AS net_contribution,
  s.sales_cnt,
  r.return_cnt
FROM target_customers tc
LEFT JOIN sales_agg s ON tc.cust_sk = s.ss_customer_sk
LEFT JOIN returns_agg r ON tc.cust_sk = r.sr_customer_sk
JOIN customer c ON tc.cust_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason rr ON sr.sr_reason_sk = rr.r_reason_sk
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND rr.r_reason_desc = 'Damaged'
      )
  AND c.c_preferred_cust_flag = 'Y'
  AND ca.ca_gmt_offset = -5.00
  AND ca.ca_location_type = 'single family'
  AND ca.ca_suite_number LIKE 'Suite %'
  AND tc.metric > (SELECT AVG(metric) FROM target_customers)
ORDER BY net_contribution DESC NULLS LAST
LIMIT 100
