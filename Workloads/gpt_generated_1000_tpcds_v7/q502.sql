SELECT i.i_item_id,
       i.i_product_name,
       SUM(cs.cs_quantity) AS total_quantity,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_ext_ship_cost > 500
  AND i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
GROUP BY i.i_item_id, i.i_product_name
ORDER BY total_net_paid DESC
LIMIT 10
