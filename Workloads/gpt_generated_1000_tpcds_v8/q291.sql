/*
  Goal: Identify high‑value sales by billing address for radio promotions, showing total paid and quantity per address and catalog department after applying multiple realistic filters, deduplicating across departments, and intersecting address key sets.
*/
WITH
  sales_agg AS (
    SELECT
      cs_bill_addr_sk,
      cs_promo_sk,
      cs_catalog_page_sk,
      SUM(cs_net_paid_inc_ship) AS total_paid,
      SUM(cs_quantity) AS total_qty,
      AVG(cs_sales_price) AS avg_price,
      COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales
    WHERE cs_net_paid_inc_ship > 500
      AND cs_net_paid_inc_ship < 15000
      AND cs_sales_price >= 20
      AND cs_sales_price <= 150
      AND cs_quantity > 0
      AND cs_promo_sk IS NOT NULL
    GROUP BY cs_bill_addr_sk, cs_promo_sk, cs_catalog_page_sk
  ),
  promo_filtered AS (
    SELECT
      p_promo_sk,
      p_promo_name,
      p_end_date_sk,
      p_channel_radio,
      p_discount_active
    FROM tpcds.promotion
    WHERE p_channel_radio = 'N'
      AND p_end_date_sk > 2450300
      AND p_discount_active = 'Y'
  ),
  address_filtered AS (
    SELECT
      ca_address_sk,
      ca_city,
      ca_state,
      ca_suite_number,
      ca_street_name,
      ca_street_number
    FROM tpcds.customer_address
    WHERE ca_suite_number LIKE 'Suite %'
      AND ca_city IN ('Jackson', 'Wilson', 'Lincoln')
      AND ca_state = 'CA'
  ),
  promo_sales_a AS (
    SELECT
      sa.cs_bill_addr_sk,
      pa.p_promo_name,
      cp.cp_department,
      sa.total_paid,
      sa.total_qty
    FROM sales_agg sa
    JOIN promo_filtered pa ON sa.cs_promo_sk = pa.p_promo_sk
    JOIN tpcds.catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
  ),
  promo_sales_b AS (
    SELECT
      sa.cs_bill_addr_sk,
      pa.p_promo_name,
      cp.cp_department,
      sa.total_paid,
      sa.total_qty
    FROM sales_agg sa
    JOIN promo_filtered pa ON sa.cs_promo_sk = pa.p_promo_sk
    JOIN tpcds.catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Books'
  ),
  union_promo_sales AS (
    SELECT DISTINCT cs_bill_addr_sk, p_promo_name, cp_department, total_paid, total_qty
    FROM promo_sales_a
    UNION
    SELECT DISTINCT cs_bill_addr_sk, p_promo_name, cp_department, total_paid, total_qty
    FROM promo_sales_b
  ),
  addr_keys_sales AS (
    SELECT DISTINCT cs_bill_addr_sk
    FROM tpcds.catalog_sales
    WHERE cs_net_paid_inc_ship > 1000
  ),
  addr_keys_address AS (
    SELECT DISTINCT ca_address_sk
    FROM tpcds.customer_address
    WHERE ca_suite_number = 'Suite 200'
  ),
  common_addr_keys AS (
    SELECT cs_bill_addr_sk
    FROM addr_keys_sales
    INTERSECT
    SELECT ca_address_sk
    FROM addr_keys_address
  )
SELECT
  up.cs_bill_addr_sk,
  af.ca_city,
  af.ca_state,
  up.p_promo_name,
  up.cp_department,
  up.total_paid,
  up.total_qty,
  up.total_paid / NULLIF(up.total_qty, 0) AS avg_paid_per_qty
FROM union_promo_sales up
JOIN address_filtered af ON up.cs_bill_addr_sk = af.ca_address_sk
WHERE up.cs_bill_addr_sk IN (SELECT cs_bill_addr_sk FROM common_addr_keys)
ORDER BY up.total_paid DESC
LIMIT 100
