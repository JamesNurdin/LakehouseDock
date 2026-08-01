WITH ware_info AS (
   SELECT
       w.w_warehouse_sk,
       w.w_warehouse_id,
       w.w_warehouse_name,
       w.w_city,
       w.w_country,
       w.w_warehouse_sq_ft,
       CASE WHEN regexp_like(w.w_city, '^N.*') THEN 1 ELSE 0 END AS city_starts_n,
       regexp_extract(w.w_street_number, '(\\d+)', 1) AS street_num_digits
   FROM warehouse w
   WHERE w.w_country = 'United States'
),

inv_agg AS (
   SELECT
       i.inv_warehouse_sk,
       COUNT(*) AS item_count,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       CASE WHEN SUM(i.inv_quantity_on_hand) > 1000 THEN 'HIGH' ELSE 'LOW' END AS qty_category
   FROM inventory i
   GROUP BY i.inv_warehouse_sk
),

large_sq AS (
   SELECT w_warehouse_sk FROM warehouse WHERE w_warehouse_sq_ft > 600000
),

city_n AS (
   SELECT w_warehouse_sk FROM warehouse WHERE regexp_like(w_city, '^N.*')
),

intersect_keys AS (
   SELECT w_warehouse_sk FROM large_sq INTERSECT SELECT w_warehouse_sk FROM city_n
)

SELECT
   combined.w_warehouse_id,
   combined.w_warehouse_name,
   combined.city_starts_n,
   combined.item_count,
   combined.total_qty,
   combined.qty_category,
   combined.name_prefix,
   combined.name_len,
   combined.item_26_cnt
FROM (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       w.city_starts_n,
       i.item_count,
       i.total_qty,
       i.qty_category,
       nl.name_prefix,
       nl.name_len,
       (SELECT COUNT(*) FROM inventory inv_sub WHERE inv_sub.inv_warehouse_sk = w.w_warehouse_sk AND inv_sub.inv_item_sk = 26) AS item_26_cnt
   FROM ware_info w
   JOIN inv_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN LATERAL (
       SELECT substring(w.w_warehouse_name, 1, 2) AS name_prefix,
              length(w.w_warehouse_name) AS name_len
   ) nl ON true
   WHERE w.w_warehouse_name LIKE 'A%'
     AND NOT EXISTS (
         SELECT 1 FROM inventory i2
         WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
           AND i2.inv_quantity_on_hand < 0
     )
     AND w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM intersect_keys)

   UNION

   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       w.city_starts_n,
       i.item_count,
       i.total_qty,
       i.qty_category,
       nl.name_prefix,
       nl.name_len,
       (SELECT COUNT(*) FROM inventory inv_sub WHERE inv_sub.inv_warehouse_sk = w.w_warehouse_sk AND inv_sub.inv_item_sk = 26) AS item_26_cnt
   FROM ware_info w
   JOIN inv_agg i ON i.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN LATERAL (
       SELECT substring(w.w_warehouse_name, 1, 2) AS name_prefix,
              length(w.w_warehouse_name) AS name_len
   ) nl ON true
   WHERE regexp_like(w.w_warehouse_name, '^B.*')
     AND NOT EXISTS (
         SELECT 1 FROM inventory i2
         WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
           AND i2.inv_quantity_on_hand < 0
     )
     AND w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM intersect_keys)
) AS combined
ORDER BY combined.total_qty DESC
LIMIT 100
