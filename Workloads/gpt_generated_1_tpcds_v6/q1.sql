WITH cr AS (
    SELECT *
    FROM catalog_returns
),
wr AS (
    SELECT *
    FROM web_returns
)
SELECT
    cp.cp_department,
    wp.wp_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    (SELECT AVG(cr2.cr_return_amount)
       FROM catalog_returns cr2
       JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
      WHERE cp2.cp_department = cp.cp_department) AS avg_return_amount_per_dept,
    (SELECT COUNT(DISTINCT ca_state)
       FROM customer_address ca_sub
      WHERE ca_sub.ca_country = 'United States') AS distinct_us_states
FROM cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_page cp_dup                -- second alias of the same dimension
  ON cr.cr_catalog_page_sk = cp_dup.cp_catalog_page_sk
JOIN time_dim t                         -- shared time dimension for both returns
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_address ca_refunded_cat
  ON cr.cr_refunded_addr_sk = ca_refunded_cat.ca_address_sk
JOIN customer_address ca_returning_cat
  ON cr.cr_returning_addr_sk = ca_returning_cat.ca_address_sk
JOIN wr
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_refunded_wr
  ON wr.wr_refunded_addr_sk = ca_refunded_wr.ca_address_sk
JOIN customer_address ca_returning_wr
  ON wr.wr_returning_addr_sk = ca_returning_wr.ca_address_sk
GROUP BY ROLLUP (cp.cp_department, wp.wp_type)
HAVING (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) > 1000
ORDER BY total_catalog_return_amount DESC, total_web_return_amount DESC
LIMIT 100
