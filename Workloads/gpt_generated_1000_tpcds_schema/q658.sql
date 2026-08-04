WITH
catalog_agg AS (
  SELECT
    cs_bill_addr_sk AS address_sk,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_coupon_amt) AS avg_coupon,
    SUM(cs_ext_discount_amt) AS total_discount
  FROM catalog_sales
  WHERE cs_coupon_amt > 100.00
    AND cs_net_paid_inc_ship BETWEEN 500.00 AND 20000.00
    AND cs_ship_customer_sk IN (4098294, 8238393, 2922254)
    AND cs_sold_date_sk BETWEEN 2450000 AND 2451000
    AND cs_quantity >= 2
    AND cs_wholesale_cost > 10.00
  GROUP BY cs_bill_addr_sk
),
store_agg AS (
  SELECT
    ss_addr_sk AS address_sk,
    COUNT(*) AS store_txn_cnt,
    SUM(ss_net_paid) AS store_total_net,
    MAX(ss_ext_wholesale_cost) AS max_wholesale,
    MIN(ss_list_price) AS min_list_price,
    AVG(ss_coupon_amt) AS avg_store_coupon
  FROM store_sales
  WHERE ss_coupon_amt > 0
    AND ss_net_paid_inc_tax > 1000.00
    AND ss_quantity BETWEEN 1 AND 10
    AND ss_wholesale_cost < 100.00
    AND ss_sold_date_sk BETWEEN 2450000 AND 2452000
    AND ss_list_price > 20.00
  GROUP BY ss_addr_sk
),
full_addr AS (
  SELECT
    COALESCE(ca.ca_address_sk, c.address_sk, s.address_sk) AS address_sk,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    c.order_cnt,
    c.total_net_paid,
    c.avg_coupon,
    s.store_txn_cnt,
    s.store_total_net,
    s.max_wholesale,
    s.min_list_price,
    CASE
      WHEN c.total_net_paid > 10000 THEN 'HIGH_CAT'
      WHEN s.store_total_net > 8000 THEN 'HIGH_STORE'
      ELSE 'NORMAL'
    END AS revenue_tier
  FROM catalog_agg c
  FULL OUTER JOIN store_agg s ON c.address_sk = s.address_sk
  LEFT JOIN customer_address ca ON ca.ca_address_sk = COALESCE(c.address_sk, s.address_sk)
),
catalog_only AS (
  SELECT address_sk FROM catalog_agg
  WHERE NOT EXISTS (
    SELECT 1 FROM store_agg s WHERE s.address_sk = catalog_agg.address_sk
  )
),
high_value_addresses AS (
  SELECT address_sk FROM catalog_agg WHERE total_net_paid > 15000
  EXCEPT
  SELECT address_sk FROM store_agg WHERE store_total_net > 15000
),
mid_value_addresses AS (
  SELECT address_sk FROM catalog_agg WHERE total_net_paid BETWEEN 5000 AND 15000
  INTERSECT
  SELECT address_sk FROM store_agg WHERE store_total_net BETWEEN 5000 AND 15000
)
SELECT DISTINCT
  f.address_sk,
  f.ca_city,
  f.ca_state,
  f.ca_zip,
  f.order_cnt,
  f.store_txn_cnt,
  f.total_net_paid,
  f.store_total_net,
  f.revenue_tier
FROM full_addr f
WHERE f.address_sk IN (SELECT address_sk FROM high_value_addresses)
   OR f.address_sk IN (SELECT address_sk FROM mid_value_addresses)
   OR f.address_sk IN (SELECT address_sk FROM catalog_only)
ORDER BY f.total_net_paid DESC NULLS LAST, f.store_total_net DESC
LIMIT 100
