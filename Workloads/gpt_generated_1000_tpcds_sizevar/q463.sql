WITH sales_by_wh AS (
  SELECT
    cs_warehouse_sk,
    cs_bill_hdemo_sk,
    cs_bill_addr_sk,
    SUM(cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE cs_ext_tax > 50
    AND cs_wholesale_cost BETWEEN 20 AND 80
    AND cs_quantity >= 1
  GROUP BY cs_warehouse_sk, cs_bill_hdemo_sk, cs_bill_addr_sk
),
hd_info AS (
  SELECT hd_demo_sk, hd_buy_potential, hd_vehicle_count, hd_dep_count
  FROM household_demographics
  WHERE hd_buy_potential = '1001-5000'
    AND hd_vehicle_count >= 1
),
valid_warehouses AS (
  SELECT cs_warehouse_sk AS w_sk FROM sales_by_wh
  INTERSECT
  SELECT w_warehouse_sk FROM warehouse WHERE w_gmt_offset >= -5
)
SELECT
  w.w_state,
  COUNT(DISTINCT sb.cs_bill_addr_sk) AS num_bill_addresses,
  SUM(sb.total_net_paid) AS sum_total_net_paid,
  AVG(sb.total_net_paid) AS avg_total_net_paid
FROM sales_by_wh sb
JOIN valid_warehouses vw ON sb.cs_warehouse_sk = vw.w_sk
JOIN hd_info hd ON sb.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON sb.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON sb.cs_bill_addr_sk = ca.ca_address_sk
WHERE w.w_warehouse_sq_ft > 500000
  AND ca.ca_country = 'United States'
  AND sb.total_net_paid > (SELECT AVG(cs_net_paid_inc_tax) FROM catalog_sales)
GROUP BY w.w_state
HAVING AVG(sb.total_net_paid) > 1000
ORDER BY avg_total_net_paid DESC
LIMIT 100
