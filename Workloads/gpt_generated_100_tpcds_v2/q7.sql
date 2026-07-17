SELECT i.i_category,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_count
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_quantity >= 5
  AND i.i_category = 'Electronics'
GROUP BY i.i_category
