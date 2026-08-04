WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
  ),
  intersect_items AS (
    SELECT cs_item_sk
    FROM catalog_sales
    WHERE cs_quantity > 2
    INTERSECT
    SELECT cs_item_sk
    FROM catalog_sales
    WHERE cs_ext_discount_amt < 50
  ),
  union_sales AS (
    SELECT cs_item_sk, cs_ext_sales_price
    FROM catalog_sales
    WHERE cs_wholesale_cost > 20
    UNION
    SELECT cs_item_sk, cs_ext_sales_price
    FROM catalog_sales
    WHERE cs_wholesale_cost <= 20
  )
SELECT
  i.i_brand,
  hd.hd_buy_potential,
  hd.hd_demo_sk,
  SUM(s.cs_ext_sales_price) AS total_sales,
  AVG(s.cs_wholesale_cost) AS avg_wholesale_cost,
  COUNT(DISTINCT s.cs_order_number) AS orders_cnt,
  MIN(s.cs_ext_discount_amt) AS min_discount,
  MAX(s.cs_net_profit) AS max_profit,
  (
    SELECT SUM(cs2.cs_ext_sales_price)
    FROM catalog_sales cs2
    JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
    WHERE i2.i_brand = i.i_brand
      AND cs2.cs_bill_hdemo_sk = hd.hd_demo_sk
  ) AS brand_hdemo_sales
FROM sampled_sales s
JOIN household_demographics hd
  ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i
  ON s.cs_item_sk = i.i_item_sk
JOIN intersect_items ii
  ON s.cs_item_sk = ii.cs_item_sk
JOIN union_sales us
  ON s.cs_item_sk = us.cs_item_sk
WHERE
  s.cs_ext_sales_price > 1000
  AND s.cs_quantity BETWEEN 1 AND 5
  AND i.i_category = 'Electronics'
  AND i.i_rec_start_date >= DATE '1999-10-27'
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY
  i.i_brand,
  hd.hd_buy_potential,
  hd.hd_demo_sk
ORDER BY total_sales DESC
LIMIT 100
