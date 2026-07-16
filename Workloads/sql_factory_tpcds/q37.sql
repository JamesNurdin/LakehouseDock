SELECT
  i.i_item_id,
  cs.cs_warehouse_sk AS warehouse_id,
  SUM(cs.cs_quantity) AS total_sold_quantity,
  AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
  CASE
    WHEN AVG(inv.inv_quantity_on_hand) = 0 THEN NULL
    ELSE SUM(cs.cs_quantity) / AVG(inv.inv_quantity_on_hand)
  END AS turnover_ratio,
  DENSE_RANK() OVER (
    PARTITION BY i.i_item_id
    ORDER BY
      CASE
        WHEN AVG(inv.inv_quantity_on_hand) = 0 THEN 0
        ELSE SUM(cs.cs_quantity) / AVG(inv.inv_quantity_on_hand)
      END DESC
  ) AS turnover_rank,
  MAX(p.p_promo_name) AS any_promo_name
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = cs.cs_item_sk
  AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
GROUP BY i.i_item_id, cs.cs_warehouse_sk
HAVING SUM(cs.cs_quantity) > 0
ORDER BY turnover_ratio DESC
LIMIT 50
