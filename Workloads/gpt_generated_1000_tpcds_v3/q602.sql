WITH filtered_sales AS (
    SELECT cs.cs_item_sk,
           cs.cs_ship_mode_sk,
           cs.cs_ext_ship_cost,
           cs.cs_list_price,
           cs.cs_net_paid,
           cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500
      AND cs.cs_list_price BETWEEN 50 AND 200
)
SELECT i.i_brand,
       i.i_manufact,
       sm.sm_carrier,
       SUM(fs.cs_net_paid) AS total_net_paid,
       AVG(fs.cs_ext_ship_cost) AS avg_ship_cost,
       COUNT(*) AS order_count,
       MAX(fs.cs_list_price) AS max_list_price,
       (
           SELECT SUM(cs2.cs_net_paid)
           FROM catalog_sales cs2
           JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
           WHERE i2.i_brand = i.i_brand
       ) AS brand_total_net_paid
FROM filtered_sales fs
JOIN item i ON fs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE i.i_brand_id IN (10008011, 6016006)
  AND i.i_brand = 'importoamalg #1'
  AND sm.sm_code = 'AIR'
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs3
      WHERE cs3.cs_item_sk = fs.cs_item_sk
        AND cs3.cs_quantity > 5
  )
GROUP BY i.i_brand,
         i.i_manufact,
         sm.sm_carrier
ORDER BY total_net_paid DESC
LIMIT 100
