WITH
  sales_base AS (
    SELECT
      ss.ss_customer_sk,
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      ss.ss_quantity,
      ss.ss_ext_tax,
      ss.ss_promo_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 2
      AND ss.ss_net_paid > 50
  ),
  returns_base AS (
    SELECT
      wr.wr_returning_customer_sk,
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_reason_sk,
      wr.wr_web_page_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 20
      AND wr.wr_return_quantity > 1
  ),
  customer_dim AS (
    SELECT
      c.c_customer_sk,
      ca.ca_state,
      ca.ca_country,
      c.c_first_name,
      c.c_last_name
    FROM customer c
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
  ),
  date_dim_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq, d_day_name
    FROM date_dim
    WHERE d_year = 2001
  ),
  promo_dim AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_channel_tv,
           p.p_discount_active
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
  ),
  call_center_dim AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_market_manager,
           cc.cc_division,
           cc.cc_closed_date_sk
    FROM call_center cc
    WHERE cc.cc_market_manager = 'Mark Jimenez'
  ),
  catalog_page_dim AS (
    SELECT cp.cp_catalog_page_sk,
           cp.cp_department,
           cp.cp_start_date_sk
    FROM catalog_page cp
    WHERE cp.cp_department = 'Electronics'
  ),
  web_site_dim AS (
    SELECT ws.web_site_sk,
           ws.web_name,
           ws.web_open_date_sk,
           ws.web_class
    FROM web_site ws
    WHERE ws.web_class = 'Consumer'
  ),
  web_page_dim AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_type,
           wp.wp_creation_date_sk
    FROM web_page wp
    WHERE wp.wp_type = 'Content'
  ),
  reason_dim AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc
    FROM reason r
    WHERE r.r_reason_desc LIKE '%damaged%'
  ),
  intersect_customers AS (
    SELECT DISTINCT sb.ss_customer_sk AS cust_sk
    FROM sales_base sb
    JOIN date_dim_filtered d ON sb.ss_sold_date_sk = d.d_date_sk
    INTERSECT
    SELECT DISTINCT rb.wr_returning_customer_sk AS cust_sk
    FROM returns_base rb
    JOIN date_dim_filtered d ON rb.wr_returned_date_sk = d.d_date_sk
  ),
  catalog_site_full AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      ws.web_site_sk,
      ws.web_name,
      COALESCE(cp.cp_start_date_sk, ws.web_open_date_sk) AS join_date_sk
    FROM (
      SELECT cp.cp_catalog_page_sk, cp.cp_department, cp.cp_start_date_sk
      FROM catalog_page_dim cp
      JOIN date_dim_filtered d ON cp.cp_start_date_sk = d.d_date_sk
    ) cp
    FULL OUTER JOIN (
      SELECT ws.web_site_sk, ws.web_name, ws.web_open_date_sk
      FROM web_site_dim ws
      JOIN date_dim_filtered d ON ws.web_open_date_sk = d.d_date_sk
    ) ws
      ON cp.cp_start_date_sk = ws.web_open_date_sk
  )
SELECT
  d.d_year,
  ca.ca_state,
  cc.cc_division,
  p.p_channel_tv,
  wp.wp_type,
  COUNT(DISTINCT sb.ss_ticket_number)               AS total_transactions,
  SUM(sb.ss_net_paid)                               AS total_sales,
  AVG(sb.ss_ext_tax)                                AS avg_tax,
  SUM(rb.wr_return_amt)                            AS total_return_amount,
  COUNT(DISTINCT rb.wr_reason_sk)                  AS distinct_return_reasons,
  COUNT(DISTINCT wp.wp_web_page_sk)                AS distinct_web_pages,
  COUNT(DISTINCT cs.cp_catalog_page_sk)            AS distinct_catalog_pages,
  COUNT(DISTINCT cs.web_site_sk)                   AS distinct_web_sites
FROM sales_base sb
JOIN date_dim_filtered d
  ON sb.ss_sold_date_sk = d.d_date_sk
JOIN customer_dim ca
  ON sb.ss_customer_sk = ca.c_customer_sk
JOIN promo_dim p
  ON sb.ss_promo_sk = p.p_promo_sk
JOIN call_center_dim cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN returns_base rb
  ON sb.ss_customer_sk = rb.wr_returning_customer_sk
  AND rb.wr_returned_date_sk = d.d_date_sk
JOIN reason_dim r
  ON rb.wr_reason_sk = r.r_reason_sk
JOIN intersect_customers ic
  ON sb.ss_customer_sk = ic.cust_sk
JOIN catalog_site_full cs
  ON cs.join_date_sk = d.d_date_sk
JOIN web_page_dim wp
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE ca.ca_country = 'United States'
GROUP BY CUBE (d.d_year, ca.ca_state, cc.cc_division, p.p_channel_tv, wp.wp_type)
ORDER BY d.d_year DESC, ca.ca_state, cc.cc_division, p.p_channel_tv, wp.wp_type
