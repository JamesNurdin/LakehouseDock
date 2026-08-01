WITH
  union_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      SUM(cs.cs_net_profit) AS profit,
      COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_sales_price > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_brand
  ),
  web_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      SUM(ws.ws_ext_sales_price) AS sales_amount,
      SUM(ws.ws_net_profit) AS profit,
      COUNT(*) AS orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_sales_price > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_brand
  ),
  union_all_sales AS (
    SELECT * FROM union_sales
    UNION
    SELECT * FROM web_sales_agg
  ),
  intersect_items AS (
    SELECT i_item_sk FROM union_sales
    INTERSECT
    SELECT i_item_sk FROM web_sales_agg
  ),
  filtered_sales AS (
    SELECT
      ua.i_item_sk,
      ua.i_item_id,
      ua.i_category,
      ua.i_brand,
      ua.sales_amount,
      ua.profit,
      ua.orders,
      CASE
        WHEN ua.profit > 0 THEN 'POSITIVE'
        WHEN ua.profit = 0 THEN 'ZERO'
        ELSE 'NEGATIVE'
      END AS profit_flag,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_item_sk = ua.i_item_sk
      ) AS total_inventory,
      ROW_NUMBER() OVER (PARTITION BY ua.i_category ORDER BY ua.sales_amount DESC) AS rn
    FROM union_all_sales ua
    JOIN item i ON ua.i_item_sk = i.i_item_sk
    WHERE ua.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND ua.i_item_sk NOT IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand = 0)
  )
SELECT
  i_category,
  i_brand,
  profit_flag,
  SUM(sales_amount) AS total_sales,
  SUM(profit) AS total_profit,
  SUM(orders) AS total_orders,
  SUM(total_inventory) AS total_inventory,
  COUNT(DISTINCT i_item_id) AS distinct_items
FROM filtered_sales
GROUP BY ROLLUP (i_category, i_brand, profit_flag)
ORDER BY i_category NULLS LAST,
         i_brand NULLS LAST,
         profit_flag NULLS LAST
LIMIT 100
