WITH
  cs AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_catalog_page_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_sales_price,
      cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_sales_price > 100
  ),
  cp AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cp.cp_type
    FROM catalog_page cp
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_type = 'A'
  ),
  c AS (
    SELECT
      c.c_customer_sk,
      c.c_last_name,
      c.c_preferred_cust_flag
    FROM customer c
    WHERE c.c_last_name = 'Rubio'
      AND c.c_preferred_cust_flag = 'Y'
  ),
  hd AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count
    FROM household_demographics hd
    WHERE hd.hd_buy_potential = '5001-10000'
      AND hd.hd_dep_count >= 2
  ),
  sr AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_return_amt,
      sr.sr_fee
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2001
      AND sr.sr_fee > 50
  ),
  cr AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    WHERE d_cr.d_year = 2001
      AND cr.cr_return_amount > 50
  ),
  wr AS (
    SELECT
      wr.wr_refunded_customer_sk,
      wr.wr_fee,
      wr.wr_web_page_sk
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2001
      AND wr.wr_fee < 20
  ),
  wp AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_type
    FROM web_page wp
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE d_wp.d_year = 2001
      AND wp.wp_type = 'content'
  )
SELECT
  d_sales.d_year,
  cp.cp_department,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(COALESCE(sr.sr_return_amt, 0.0)) AS total_store_return_amt,
  SUM(COALESCE(cr.cr_return_amount, 0.0)) AS total_catalog_return_amt,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(
    CASE
      WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit
      ELSE 0
    END
  ) AS total_positive_profit,
  AVG(cs.cs_quantity) AS avg_quantity,
  MAX(cs.cs_sales_price) AS max_sales_price,
  MIN(cs.cs_sales_price) AS min_sales_price
FROM cs
JOIN cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d_sales.d_year = 2001
  AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
  )
GROUP BY d_sales.d_year, cp.cp_department
ORDER BY total_net_paid DESC
LIMIT 100
