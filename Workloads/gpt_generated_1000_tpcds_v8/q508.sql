WITH
  catalog_agg AS (
    SELECT
      i.i_category AS category,
      cc.cc_name AS call_center,
      SUM(cs.cs_net_profit) AS catalog_profit,
      SUM(cs.cs_quantity) AS catalog_qty
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_category_id IN (5, 6)
    GROUP BY ROLLUP (i.i_category, cc.cc_name)
  ),
  store_agg AS (
    SELECT
      i.i_category AS category,
      'Store' AS call_center,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (5, 6)
    GROUP BY ROLLUP (i.i_category)
  ),
  inventory_agg AS (
    SELECT
      i.i_category AS category,
      SUM(inv.inv_quantity_on_hand) AS on_hand_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category
  ),
  avg_profit_cte AS (
    SELECT AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
  ),
  catalog_only_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT ss.ss_item_sk
    FROM store_sales ss
  ),
  catalog_only_detail AS (
    SELECT
      i.i_category AS category,
      COUNT(*) AS item_cnt,
      SUM(cs.cs_net_profit) AS profit_sum
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_item_sk IN (SELECT cs_item_sk FROM catalog_only_items)
    GROUP BY i.i_category
  )
SELECT
  COALESCE(ca.category, sa.category) AS category,
  COALESCE(ca.call_center, sa.call_center) AS source,
  ca.catalog_profit,
  sa.store_profit,
  ia.on_hand_qty,
  (SELECT avg_profit FROM avg_profit_cte) AS overall_avg_profit
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
  ON ca.category = sa.category
LEFT JOIN inventory_agg ia
  ON COALESCE(ca.category, sa.category) = ia.category
WHERE COALESCE(ca.catalog_profit, 0) > (SELECT avg_profit FROM avg_profit_cte)
   OR COALESCE(sa.store_profit, 0) > (SELECT avg_profit FROM avg_profit_cte)

UNION

SELECT
  cod.category,
  'CatalogOnly' AS source,
  cod.profit_sum AS catalog_profit,
  NULL AS store_profit,
  NULL AS on_hand_qty,
  (SELECT avg_profit FROM avg_profit_cte) AS overall_avg_profit
FROM catalog_only_detail cod
WHERE cod.category IN (
        SELECT i_category
        FROM item
        WHERE i_units = 'Ton'
      )
ORDER BY category, source
LIMIT 100
