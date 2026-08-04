WITH
  -- Items whose description contains a three‑digit pattern and whose category starts with 'Elec'
  item_filtered AS (
    SELECT i_item_sk,
           i_item_id,
           i_item_desc,
           i_category,
           i_manager_id,
           i_class_id
    FROM   item
    WHERE  regexp_like(i_item_desc, '\\d{3}')
      AND  i_category LIKE 'Elec%'
  ),
  -- Items that have an active email promotion whose name contains the word "Sale"
  promo_items AS (
    SELECT i.i_item_sk
    FROM   promotion p
    JOIN   item i ON p.p_item_sk = i.i_item_sk
    WHERE  p.p_channel_email = 'Y'
      AND  regexp_extract(p.p_promo_name, '(.*)Sale', 1) IS NOT NULL
  ),
  -- First subset: manager id greater than 20
  item_subset1 AS (
    SELECT i_item_id
    FROM   item_filtered
    WHERE  i_manager_id > 20
  ),
  -- Second subset: class id in a small list
  item_subset2 AS (
    SELECT i_item_id
    FROM   item_filtered
    WHERE  i_class_id IN (5, 7, 8)
  ),
  -- Items that belong to **both** subsets
  intersect_items AS (
    SELECT i_item_id FROM item_subset1
    INTERSECT
    SELECT i_item_id FROM item_subset2
  ),
  -- Sample a small random slice of inventory for later join
  sampled_inventory AS (
    SELECT *
    FROM   inventory TABLESAMPLE BERNOULLI (10)
    WHERE  inv_quantity_on_hand > 600
  ),
  -- Two sales periods that will be unioned (distinct)
  sales_a AS (
    SELECT *
    FROM   catalog_sales
    WHERE  cs_sold_date_sk BETWEEN 2450000 AND 2450100
  ),
  sales_b AS (
    SELECT *
    FROM   catalog_sales
    WHERE  cs_sold_date_sk BETWEEN 2450200 AND 2450300
  ),
  union_sales AS (
    SELECT * FROM sales_a
    UNION
    SELECT * FROM sales_b
  ),
  -- Expand the words in the item description for the intersected items
  word_counts AS (
    SELECT i.i_item_id,
           word,
           COUNT(*) AS word_occurrences
    FROM   intersect_items ii
    JOIN   item i ON i.i_item_id = ii.i_item_id
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    GROUP BY i.i_item_id, word
  )
SELECT
  w.w_warehouse_name,
  CONCAT(w.w_city, ', ', w.w_state) AS location,
  i.i_item_id,
  SUM(us.cs_net_paid)            AS total_net_paid,
  COUNT(DISTINCT us.cs_order_number) AS orders,
  MAX(us.cs_net_profit)          AS max_profit,
  wc.word,
  wc.word_occurrences
FROM   union_sales us
JOIN   item i ON us.cs_item_sk = i.i_item_sk
JOIN   intersect_items ii ON i.i_item_id = ii.i_item_id
JOIN   warehouse w ON us.cs_warehouse_sk = w.w_warehouse_sk
JOIN   sampled_inventory si ON us.cs_item_sk = si.inv_item_sk
                            AND us.cs_warehouse_sk = si.inv_warehouse_sk
LEFT JOIN word_counts wc ON i.i_item_id = wc.i_item_id
WHERE  us.cs_net_paid > 0
GROUP BY
  w.w_warehouse_name,
  w.w_city,
  w.w_state,
  i.i_item_id,
  wc.word,
  wc.word_occurrences
ORDER BY total_net_paid DESC
LIMIT 100
