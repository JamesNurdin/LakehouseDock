WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_formulation,
        REGEXP_EXTRACT(i.i_formulation, '(\\d+)', 1) AS formulation_number,
        (SELECT max(p2.p_cost)
         FROM promotion p2
         WHERE p2.p_item_sk = i.i_item_sk
           AND p2.p_discount_active = 'Y') AS max_active_promo_cost
    FROM item i
    WHERE REGEXP_LIKE(i.i_formulation, '\\d+blue')
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
)
SELECT
    w.w_warehouse_id,
    CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_full_name,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT ip.i_item_sk) AS distinct_items,
    MAX(ip.max_active_promo_cost) AS max_promo_cost,
    AVG(CAST(ip.formulation_number AS DOUBLE)) AS avg_formulation_number
FROM inventory inv
JOIN item_promo ip
  ON inv.inv_item_sk = ip.i_item_sk
JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_street_name LIKE '%Center%'
GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_city
ORDER BY total_quantity DESC
LIMIT 100
