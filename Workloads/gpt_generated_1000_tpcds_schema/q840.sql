WITH sampled_sales AS (
  SELECT *
  FROM catalog_sales TABLESAMPLE BERNOULLI (5)
),

sub_a AS (
  SELECT
    cs.cs_item_sk,
    i.i_category,
    SUM(cs.cs_ext_sales_price) AS total_sales_a
  FROM sampled_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 8 AND 12
    AND i.i_color = 'pink'
  GROUP BY cs.cs_item_sk, i.i_category
),

sub_b AS (
  SELECT
    cs.cs_item_sk,
    i.i_category,
    SUM(cs.cs_ext_sales_price) AS total_sales_b
  FROM sampled_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_vehicle_count > 0
    AND i.i_color = 'lime'
  GROUP BY cs.cs_item_sk, i.i_category
),

intersect_keys AS (
  SELECT cs_item_sk, i_category
  FROM sub_a
  INTERSECT
  SELECT cs_item_sk, i_category
  FROM sub_b
)
SELECT
  ik.cs_item_sk,
  ik.i_category
FROM intersect_keys ik
WHERE NOT EXISTS (
  SELECT 1
  FROM item i2
  WHERE i2.i_item_sk = ik.cs_item_sk
    AND i2.i_formulation LIKE '%plum%'
)
ORDER BY ik.cs_item_sk ASC
OFFSET 0 LIMIT 100
