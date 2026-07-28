WITH filtered_sales AS (
  SELECT
    cs.cs_warehouse_sk AS warehouse_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_quantity,
    promotion.p_channel_details,
    promotion.p_promo_name,
    warehouse.w_warehouse_name,
    warehouse.w_city
  FROM catalog_sales cs
  JOIN promotion ON cs.cs_promo_sk = promotion.p_promo_sk
  JOIN warehouse ON cs.cs_warehouse_sk = warehouse.w_warehouse_sk
  WHERE regexp_like(promotion.p_channel_details, '(?i)common')
    AND promotion.p_discount_active = 'Y'
    AND warehouse.w_city LIKE 'A%'
    AND EXISTS (
      SELECT 1
      FROM inventory inv
      WHERE inv.inv_warehouse_sk = warehouse.w_warehouse_sk
        AND inv.inv_quantity_on_hand > 0
    )
)
SELECT
  w_warehouse_name,
  substring(w_warehouse_name, 1, 10) AS warehouse_prefix,
  COUNT(*) AS transaction_cnt,
  SUM(net_profit) AS total_net_profit,
  AVG(net_profit) AS avg_profit_per_tx,
  (SELECT AVG(cs.cs_net_profit)
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE regexp_like(p.p_channel_details, '(?i)common')
     AND p.p_discount_active = 'Y') AS overall_avg_profit
FROM filtered_sales
GROUP BY w_warehouse_name, substring(w_warehouse_name, 1, 10)
HAVING SUM(net_profit) > (
  SELECT AVG(cs.cs_net_profit)
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE regexp_like(p.p_channel_details, '(?i)common')
    AND p.p_discount_active = 'Y'
)
ORDER BY total_net_profit DESC
LIMIT 100
