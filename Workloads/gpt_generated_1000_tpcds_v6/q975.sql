WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 10
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  item_filter AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_size,
      i.i_formulation,
      i.i_category
    FROM item i
    WHERE i.i_size = 'large'
      AND i.i_formulation LIKE '%steel%'
  ),
  sales_union AS (
    SELECT
      cs.cs_item_sk      AS item_sk,
      cs.cs_warehouse_sk AS warehouse_sk,
      cs.cs_ship_mode_sk AS ship_mode_sk,
      cs.cs_ext_sales_price AS sales_price,
      cs.cs_net_profit      AS profit,
      cs.cs_ext_discount_amt AS discount_amt,
      'catalog' AS sales_channel
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500

    UNION ALL

    SELECT
      ss.ss_item_sk      AS item_sk,
      NULL               AS warehouse_sk,
      NULL               AS ship_mode_sk,
      ss.ss_ext_sales_price AS sales_price,
      ss.ss_net_profit      AS profit,
      ss.ss_ext_discount_amt AS discount_amt,
      'store' AS sales_channel
    FROM store_sales ss
    WHERE ss.ss_ext_tax < 10

    UNION ALL

    SELECT
      ws.ws_item_sk      AS item_sk,
      ws.ws_warehouse_sk AS warehouse_sk,
      ws.ws_ship_mode_sk AS ship_mode_sk,
      ws.ws_ext_sales_price AS sales_price,
      ws.ws_net_profit      AS profit,
      ws.ws_ext_discount_amt AS discount_amt,
      'web' AS sales_channel
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
  ),
  sales_agg AS (
    SELECT
      item_sk,
      warehouse_sk,
      ship_mode_sk,
      SUM(sales_price) AS total_sales,
      SUM(profit)      AS total_profit,
      COUNT(*)         AS txn_count
    FROM sales_union
    GROUP BY item_sk, warehouse_sk, ship_mode_sk
  ),
  ranked_sales AS (
    SELECT
      sa.item_sk,
      sa.warehouse_sk,
      sa.ship_mode_sk,
      sa.total_sales,
      sa.total_profit,
      sa.txn_count,
      RANK() OVER (PARTITION BY sa.warehouse_sk ORDER BY sa.total_sales DESC) AS sales_rank
    FROM sales_agg sa
  )
SELECT DISTINCT
  i.i_item_id,
  i.i_product_name,
  w.w_warehouse_name,
  sm.sm_type AS ship_type,
  rs.total_sales,
  rs.total_profit,
  rs.txn_count,
  rs.sales_rank,
  ia.total_on_hand
FROM ranked_sales rs
JOIN item_filter i
  ON i.i_item_sk = rs.item_sk
LEFT JOIN inv_agg ia
  ON ia.inv_item_sk = rs.item_sk
 AND ia.inv_warehouse_sk = rs.warehouse_sk
LEFT JOIN warehouse w
  ON w.w_warehouse_sk = rs.warehouse_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = rs.ship_mode_sk
WHERE w.w_state = 'CA'
  AND rs.total_profit > 0
  AND rs.sales_rank <= 10
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_ext_sales_price > 2000
      )
ORDER BY rs.sales_rank, rs.total_sales DESC
LIMIT 100
