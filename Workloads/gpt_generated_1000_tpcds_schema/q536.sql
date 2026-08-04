-- Goal: Identify high‑profit manufacturers whose items also match a specific color pattern, then list sales metrics for those items while exploding the item description into words.
WITH
  high_profit AS (
    SELECT
      i.i_item_sk,
      i.i_manufact_id,
      i.i_item_desc,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_net_profit > 1000
      AND regexp_like(i.i_item_desc, '[A-Z]{3}')
    GROUP BY i.i_item_sk, i.i_manufact_id, i.i_item_desc
  ),
  color_items AS (
    SELECT i.i_item_sk, i.i_manufact_id
    FROM item i
    WHERE i.i_color LIKE '%e%'
      AND i.i_color NOT LIKE 's%'
  ),
  intersect_manufact AS (
    SELECT i_manufact_id FROM high_profit
    INTERSECT
    SELECT i_manufact_id FROM color_items
  ),
  sales_agg AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_net_paid) AS total_paid,
           COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs.cs_item_sk
  )
SELECT
  i.i_item_id,
  i.i_brand,
  i.i_category,
  i.i_manufact_id,
  concat(i.i_brand, '-', i.i_category) AS brand_category,
  sa.total_paid,
  sa.order_cnt,
  (SELECT avg(cs2.cs_net_paid) FROM catalog_sales cs2) AS avg_net_paid,
  word
FROM item i
RIGHT JOIN sales_agg sa
  ON i.i_item_sk = sa.cs_item_sk
LEFT JOIN intersect_manufact im
  ON i.i_manufact_id = im.i_manufact_id
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
WHERE im.i_manufact_id IS NOT NULL
  AND i.i_item_desc LIKE '%size%'
  AND regexp_extract(i.i_item_desc, '(\\d+)', 1) IS NOT NULL
ORDER BY sa.total_paid DESC
LIMIT 100
