WITH warehouse_words AS (
   SELECT w.w_warehouse_sk,
          w.w_warehouse_id,
          w.w_warehouse_name,
          w.w_state,
          w.w_street_name,
          w.w_street_type,
          split(w.w_warehouse_name, ' ') AS name_parts
   FROM tpcds.warehouse w
),
warehouse_unnested AS (
   SELECT ww.w_warehouse_sk,
          ww.w_warehouse_id,
          ww.w_warehouse_name,
          ww.w_state,
          ww.w_street_name,
          ww.w_street_type,
          wp.value AS name_word
   FROM warehouse_words ww
   CROSS JOIN UNNEST(ww.name_parts) WITH ORDINALITY AS wp(value, pos)
),
filtered_warehouses AS (
   SELECT w.*
   FROM warehouse_unnested w
   WHERE regexp_like(w.w_warehouse_name, '[A-Z]{2,}')
     AND w.w_street_name LIKE '%First%'
)
SELECT
    fw.w_warehouse_id,
    fw.w_warehouse_name,
    substring(fw.w_warehouse_name, 1, 5) AS name_prefix,
    regexp_extract(fw.w_warehouse_name, '(\\d+)', 1) AS extracted_number,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
    CASE WHEN SUM(cs.cs_net_profit) > (
            SELECT avg(cs_net_profit)
            FROM tpcds.catalog_sales
          ) THEN 'HIGH' ELSE 'NORMAL' END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY fw.w_state ORDER BY SUM(cs.cs_net_paid) DESC) AS rank_within_state,
    COUNT(i.inv_quantity_on_hand) FILTER (WHERE i.inv_quantity_on_hand > 500) AS high_inventory_warehouse_count
FROM filtered_warehouses fw
JOIN tpcds.catalog_sales cs
   ON cs.cs_warehouse_sk = fw.w_warehouse_sk
JOIN tpcds.inventory i
   ON i.inv_warehouse_sk = fw.w_warehouse_sk
WHERE EXISTS (
      SELECT 1
      FROM tpcds.catalog_sales cs2
      WHERE cs2.cs_item_sk = cs.cs_item_sk
        AND cs2.cs_quantity > 10
)
AND fw.w_warehouse_sk IN (
      SELECT inv.inv_warehouse_sk FROM tpcds.inventory inv WHERE inv.inv_quantity_on_hand > 500
      INTERSECT
      SELECT cs3.cs_warehouse_sk FROM tpcds.catalog_sales cs3 WHERE cs3.cs_quantity > 5
)
GROUP BY
    fw.w_warehouse_id,
    fw.w_warehouse_name,
    fw.w_state,
    fw.w_street_name,
    fw.w_street_type,
    fw.w_warehouse_sk,
    substring(fw.w_warehouse_name, 1, 5),
    regexp_extract(fw.w_warehouse_name, '(\\d+)', 1)
ORDER BY total_net_paid DESC
LIMIT 20
