SELECT
  CAST(ss.ss_customer_id AS integer) AS cid,
  COUNT(CASE WHEN i.i_class_id = 1  THEN 1 END) AS id1,
  COUNT(CASE WHEN i.i_class_id = 3  THEN 1 END) AS id3,
  COUNT(CASE WHEN i.i_class_id = 5  THEN 1 END) AS id5,
  COUNT(CASE WHEN i.i_class_id = 7  THEN 1 END) AS id7,
  COUNT(CASE WHEN i.i_class_id = 9  THEN 1 END) AS id9,
  COUNT(CASE WHEN i.i_class_id = 11 THEN 1 END) AS id11,
  COUNT(CASE WHEN i.i_class_id = 13 THEN 1 END) AS id13,
  COUNT(CASE WHEN i.i_class_id = 15 THEN 1 END) AS id15,
  COUNT(CASE WHEN i.i_class_id = 2  THEN 1 END) AS id2,
  COUNT(CASE WHEN i.i_class_id = 4  THEN 1 END) AS id4,
  COUNT(CASE WHEN i.i_class_id = 6  THEN 1 END) AS id6,
  COUNT(CASE WHEN i.i_class_id = 8  THEN 1 END) AS id8,
  COUNT(CASE WHEN i.i_class_id = 10 THEN 1 END) AS id10,
  COUNT(CASE WHEN i.i_class_id = 14 THEN 1 END) AS id14,
  COUNT(CASE WHEN i.i_class_id = 16 THEN 1 END) AS id16
FROM iceberg.bigbenchv2_sf1.store_sales ss
JOIN iceberg.bigbenchv2_sf1.items i
  ON ss.ss_item_id = i.i_item_id
WHERE i.i_category_name IN ('cat#13')
  AND ss.ss_customer_id IS NOT NULL
GROUP BY ss.ss_customer_id
HAVING COUNT(ss.ss_item_id) > 5