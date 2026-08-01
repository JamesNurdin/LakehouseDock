WITH per_customer_total AS (
  SELECT ss_customer_sk AS cust_sk,
         SUM(ss_net_profit) AS total_profit
  FROM store_sales
  GROUP BY ss_customer_sk
)
SELECT
  c.c_customer_id,
  CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
  REGEXP_EXTRACT(ca.ca_street_name, '([A-Za-z]+)', 1) AS street_name_first_word,
  SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
  p.total_profit,
  CASE
    WHEN p.total_profit > (SELECT AVG(total_profit) FROM per_customer_total) THEN 'High'
    ELSE 'Regular'
  END AS profit_category,
  (SELECT COUNT(DISTINCT wr2.wr_web_page_sk)
   FROM web_returns wr2
   JOIN web_page wp2 ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
   WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
     AND wp2.wp_type = 'content'
     AND wp2.wp_url LIKE 'http://%') AS distinct_return_pages
FROM per_customer_total p
JOIN customer c ON c.c_customer_sk = p.cust_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
  REGEXP_LIKE(ca.ca_street_name, '(Woodland|College)')
  AND c.c_email_address LIKE '%@%.com'
  AND EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_customer_sk = c.c_customer_sk
      AND td.t_shift = 'AM'
  )
  AND EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returning_customer_sk = c.c_customer_sk
      AND wp.wp_type = 'content'
      AND wp.wp_url LIKE 'http://%'
  )
ORDER BY p.total_profit DESC
LIMIT 100
