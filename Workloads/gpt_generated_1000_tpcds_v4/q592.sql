WITH base AS (
  SELECT
    cs.cs_warehouse_sk,
    cs.cs_item_sk,
    cs.cs_coupon_amt,
    cs.cs_net_paid,
    cs.cs_quantity,
    cs.cs_ship_customer_sk
  FROM tpcds.catalog_sales cs
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_city = 'Pleasant Valley'
    AND w.w_zip = '29231'
    AND cs.cs_coupon_amt > 1000
    AND cs.cs_ship_customer_sk = 10285836
)
SELECT
  w.w_city,
  COUNT(*) AS sales_cnt,
  SUM(b.cs_net_paid) AS total_net_paid,
  AVG(b.cs_coupon_amt) AS avg_coupon,
  MIN(b.cs_quantity) AS min_quantity,
  MAX(b.cs_quantity) AS max_quantity
FROM base b
JOIN tpcds.warehouse w
  ON b.cs_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
  SELECT 1
  FROM tpcds.item i
  WHERE i.i_item_sk = b.cs_item_sk
    AND i.i_brand_id IN (10005006, 2004002)
    AND i.i_wholesale_cost > 1.00
    AND i.i_category = 'Electronics'
)
GROUP BY w.w_city
ORDER BY total_net_paid DESC
LIMIT 100
