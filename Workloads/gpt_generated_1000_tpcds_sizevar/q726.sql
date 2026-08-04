WITH
  -- Subquery 1: items sold with a promotion that is not in press channel and a small size item
  sub1 AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE p.p_channel_press = 'N'
      AND i.i_size = 'small'
      AND cs.cs_quantity > 1
      AND cs.cs_sales_price > 10.00
      AND cs.cs_sold_date_sk BETWEEN 2450300 AND 2450400
  ),
  -- Subquery 2: items bought by customers with specific demographic characteristics
  sub2 AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count >= 2
      AND cd.cd_dep_college_count <= 3
      AND cs.cs_ext_discount_amt > 0.00
      AND cs.cs_net_profit > 0.00
      AND cs.cs_ship_mode_sk IS NOT NULL
  ),
  -- Intersection of the two key sets
  intersect_items AS (
    SELECT cs_item_sk FROM sub1
    INTERSECT
    SELECT cs_item_sk FROM sub2
  ),
  -- Full outer join between item and promotion (keeps unmatched rows from both sides)
  item_promo AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      p.p_promo_sk,
      p.p_promo_name,
      p.p_discount_active,
      p.p_channel_press
    FROM item i
    FULL OUTER JOIN promotion p
      ON i.i_item_sk = p.p_item_sk
  )
SELECT
  ip.i_category,
  ip.i_brand,
  CASE
    WHEN ip.p_discount_active = 'Y' THEN 'Active'
    ELSE 'Inactive'
  END AS promo_status,
  COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_net_profit) AS avg_profit,
  ROW_NUMBER() OVER (PARTITION BY ip.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rnk
FROM catalog_sales cs
JOIN intersect_items ii
  ON cs.cs_item_sk = ii.cs_item_sk
JOIN item_promo ip
  ON cs.cs_item_sk = ip.i_item_sk
LEFT JOIN customer_demographics cd
  ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
  AND ip.p_promo_name IS NOT NULL
  AND ip.p_channel_press = 'N'
GROUP BY
  ip.i_category,
  ip.i_brand,
  ip.p_discount_active,
  CASE
    WHEN ip.p_discount_active = 'Y' THEN 'Active'
    ELSE 'Inactive'
  END
HAVING COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY total_sales DESC
LIMIT 100
