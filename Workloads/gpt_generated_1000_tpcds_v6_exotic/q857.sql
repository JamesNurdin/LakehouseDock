WITH store_agg AS (
  SELECT
    i.i_item_id            AS item_id,
    i.i_product_name       AS product_name,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*)               AS store_transactions,
    (
      SELECT AVG(cs.cs_net_profit)
      FROM catalog_sales cs
      WHERE cs.cs_item_sk = i.i_item_sk
    )                     AS avg_catalog_profit,
    'store'                AS channel
  FROM store_sales ss
  INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
  INNER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  WHERE ss.ss_ext_tax > 20.00
    AND i.i_wholesale_cost BETWEEN 0.10 AND 5.00
    AND NOT EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 500
        )
  GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
),
catalog_agg AS (
  SELECT
    i.i_item_id               AS item_id,
    i.i_product_name          AS product_name,
    SUM(cs.cs_net_profit)    AS catalog_net_profit,
    COUNT(*)                  AS catalog_transactions,
    (
      SELECT AVG(ss.ss_net_profit)
      FROM store_sales ss
      WHERE ss.ss_item_sk = i.i_item_sk
    )                      AS avg_store_profit,
    'catalog'                AS channel
  FROM catalog_sales cs
  INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
  INNER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  WHERE cs.cs_ext_tax > 20.00
    AND i.i_category = 'Sports'
    AND NOT EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 500
        )
  GROUP BY i.i_item_id, i.i_product_name, i.i_item_sk
)
SELECT
  item_id,
  product_name,
  net_profit,
  transactions,
  avg_other_profit,
  channel
FROM (
  SELECT
    item_id,
    product_name,
    store_net_profit   AS net_profit,
    store_transactions AS transactions,
    avg_catalog_profit AS avg_other_profit,
    channel
  FROM store_agg
  UNION ALL
  SELECT
    item_id,
    product_name,
    catalog_net_profit AS net_profit,
    catalog_transactions AS transactions,
    avg_store_profit   AS avg_other_profit,
    channel
  FROM catalog_agg
) AS combined
ORDER BY net_profit DESC
LIMIT 100
