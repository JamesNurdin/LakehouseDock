WITH
  catalog_join AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_department,
           cp.cp_catalog_number
    FROM   catalog_page cp
    JOIN   date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE  d.d_year = 2000
      AND  cp.cp_department = 'Electronics'
  ),
  web_page_join AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_type,
           wp.wp_char_count
    FROM   web_page wp
    JOIN   date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE  d.d_year = 2000
      AND  wp.wp_char_count > 1500
  ),
  catalog_web_full AS (
    SELECT COALESCE(c.cp_catalog_page_sk, w.wp_web_page_sk) AS join_key,
           c.cp_department,
           w.wp_type
    FROM   catalog_join c
    FULL OUTER JOIN web_page_join w
           ON c.cp_catalog_page_sk = w.wp_web_page_sk
  ),
  high_spender_customers AS (
    SELECT ss_customer_sk
    FROM   store_sales
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_paid) > 10000
  ),
  ticket_store_returns AS (
    SELECT sr_ticket_number
    FROM   store_returns
    WHERE  sr_return_quantity > 0
  ),
  ticket_web_returns AS (
    SELECT CAST(wr.wr_returned_date_sk AS INTEGER) AS ticket_number
    FROM   web_returns wr
    WHERE  wr.wr_return_quantity > 0
  ),
  common_ticket_set AS (
    SELECT ticket_number FROM ticket_web_returns
    INTERSECT
    SELECT sr_ticket_number FROM ticket_store_returns
  ),
  customers_with_sales AS (
    SELECT DISTINCT ss_customer_sk AS cust_sk
    FROM   store_sales
  ),
  customers_with_returns AS (
    SELECT DISTINCT sr_customer_sk AS cust_sk
    FROM   store_returns
  ),
  customers_no_return AS (
    SELECT cust_sk
    FROM   customers_with_sales
    EXCEPT
    SELECT cust_sk
    FROM   customers_with_returns
  )
SELECT
  d.d_year,
  c.c_salutation,
  hd.hd_buy_potential,
  cwf.cp_department,
  cwf.wp_type,
  SUM(ss.ss_net_paid)               AS total_net_paid,
  AVG(i.inv_quantity_on_hand)       AS avg_inventory_qty,
  COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
  MIN(ss.ss_net_profit)             AS min_profit,
  MAX(ss.ss_net_profit)             AS max_profit
FROM   store_sales ss
JOIN   date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN   customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN   household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_web_full cwf ON cwf.join_key = cp.cp_catalog_page_sk
WHERE  d.d_year = 2000
  AND  d.d_date = DATE '2000-01-01'
  AND  c.c_salutation = 'Mrs.'
  AND  hd.hd_buy_potential = '500-1000'
  AND  i.inv_quantity_on_hand > 0
  AND  r.r_reason_desc LIKE '%defect%'
  AND  EXISTS (SELECT 1 FROM high_spender_customers hsp WHERE hsp.ss_customer_sk = ss.ss_customer_sk)
  AND  ss.ss_ticket_number IN (SELECT ticket_number FROM common_ticket_set)
  AND  ss.ss_customer_sk NOT IN (SELECT cust_sk FROM customers_no_return)
GROUP BY
  d.d_year,
  c.c_salutation,
  hd.hd_buy_potential,
  cwf.cp_department,
  cwf.wp_type
HAVING SUM(ss.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
