WITH filtered_inventory AS (
   SELECT
       inv.inv_date_sk,
       inv.inv_item_sk,
       inv.inv_warehouse_sk,
       inv.inv_quantity_on_hand
   FROM inventory inv
   WHERE inv.inv_item_sk NOT IN (
       SELECT i_item_sk
       FROM item
       WHERE i_current_price > 5
   )
),
joined AS (
   SELECT
       fi.inv_date_sk,
       fi.inv_item_sk,
       fi.inv_warehouse_sk,
       fi.inv_quantity_on_hand,
       it.i_item_id,
       it.i_current_price,
       it.i_manufact_id,
       it.i_formulation,
       it.i_color,
       it.i_size,
       CONCAT(it.i_color, '-', it.i_size) AS color_size,
       CASE
           WHEN regexp_like(it.i_formulation, 'steel') THEN 'Steel'
           WHEN it.i_formulation LIKE '%ivory%' THEN 'Ivory'
           ELSE 'Other'
       END AS formulation_category
   FROM filtered_inventory fi
   FULL OUTER JOIN item it
       ON fi.inv_item_sk = it.i_item_sk
),
aggregated AS (
   SELECT
       COALESCE(i_manufact_id, -1) AS manufact_id,
       formulation_category,
       SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_qty,
       COUNT(*) AS row_cnt,
       ROW_NUMBER() OVER (
           PARTITION BY COALESCE(i_manufact_id, -1)
           ORDER BY SUM(COALESCE(inv_quantity_on_hand, 0)) DESC
       ) AS manuf_rank
   FROM joined
   GROUP BY COALESCE(i_manufact_id, -1), formulation_category
)
SELECT
   manufact_id,
   formulation_category,
   total_qty,
   row_cnt,
   manuf_rank
FROM aggregated
WHERE total_qty > 0
ORDER BY total_qty DESC, manufact_id
OFFSET 10 LIMIT 100
