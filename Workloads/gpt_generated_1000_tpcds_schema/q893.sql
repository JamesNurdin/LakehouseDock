WITH
  -- Sample a subset of inventory (10% of rows)
  inventory_sample AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
  ),

  -- Catalog sales joined to its returns and related dimensions
  catalog_join AS (
    SELECT cs.cs_item_sk,
           cs.cs_order_number,
           cs.cs_sold_time_sk,
           cs.cs_net_profit,
           cr.cr_return_quantity,
           cr.cr_net_loss,
           i.i_item_id,
           p.p_promo_name,
           sm.sm_ship_mode_id,
           w.w_warehouse_id,
           cc.cc_call_center_id,
           td.t_hour
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
  ),

  -- Store sales (fact) – using a RIGHT OUTER JOIN to keep every store even if it has no sales
  store_join AS (
    SELECT ss.ss_store_sk,
           ss.ss_item_sk,
           ss.ss_ticket_number,
           ss.ss_quantity,
           ss.ss_net_profit,
           ss.ss_sold_time_sk,
           ss.ss_promo_sk,
           s.s_store_id,
           s.s_store_name,
           s.s_market_desc,
           s.s_state,
           i2.i_item_id,
           td2.t_hour
    FROM store_sales ss
    RIGHT OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i2
      ON ss.ss_item_sk = i2.i_item_sk
    LEFT JOIN time_dim td2
      ON ss.ss_sold_time_sk = td2.t_time_sk
  ),

  -- Store returns linked to reason description
  store_returns_join AS (
    SELECT sr.sr_ticket_number,
           sr.sr_return_quantity,
           sr.sr_net_loss,
           r.r_reason_desc
    FROM store_returns sr
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
  ),

  -- Web returns (used later for exclusion)
  web_returns_join AS (
    SELECT wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_net_loss
    FROM web_returns wr
  ),

  -- Items that appear in both catalog and store sales
  intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM catalog_join
    INTERSECT
    SELECT ss_item_sk AS item_sk FROM store_join
  ),

  -- Keep only those intersected items that were never returned via the web channel
  final_items AS (
    SELECT item_sk FROM intersect_items
    EXCEPT
    SELECT wr_item_sk FROM web_returns_join
  )

SELECT
  s.s_store_id,
  p.p_promo_name,
  COUNT(DISTINCT ss.ss_ticket_number)              AS num_transactions,
  SUM(ss.ss_net_profit)                            AS total_profit,
  SUM(CASE WHEN ss.ss_quantity > 10 THEN ss.ss_net_profit ELSE 0 END) AS profit_large_qty,
  AVG(inv.inv_quantity_on_hand)                    AS avg_inventory_on_hand,
  COUNT(DISTINCT fi.item_sk)                       AS retained_item_count,
  COUNT(DISTINCT sr.r_reason_desc)                 AS distinct_return_reasons
FROM store_join ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory_sample inv
  ON inv.inv_item_sk = ss.ss_item_sk
LEFT JOIN final_items fi
  ON fi.item_sk = ss.ss_item_sk
LEFT JOIN store_returns_join sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = ss.ss_item_sk
          AND inv2.inv_quantity_on_hand > 0
      )
GROUP BY s.s_store_id, p.p_promo_name
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY total_profit DESC
LIMIT 100
