WITH
  sales AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      ss.ss_quantity,
      ss.ss_list_price,
      ss.ss_sold_date_sk,
      i.i_item_id,
      i.i_category_id,
      s.s_store_name,
      s.s_state
    FROM (
      SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_category_id IN (1, 6, 7, 8)
      AND ss.ss_list_price > 20
      AND s.s_state = 'CA'
      AND ss.ss_quantity >= 1
      AND ss.ss_net_profit > 0
      AND ss.ss_sold_date_sk BETWEEN 2450836 AND 2450962
      AND i.i_wholesale_cost < 60
  ),
  inventory_cte AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_warehouse_sk,
      inv.inv_quantity_on_hand,
      i.i_item_id,
      i.i_category_id,
      i.i_wholesale_cost
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 100
      AND inv.inv_warehouse_sk IN (3, 4, 9)
      AND i.i_wholesale_cost < 50
  ),
  full_join AS (
    SELECT
      COALESCE(s.i_item_id, inv.i_item_id)               AS item_id,
      COALESCE(s.i_category_id, inv.i_category_id)       AS category_id,
      s.ss_ext_sales_price,
      s.ss_net_profit,
      inv.inv_quantity_on_hand,
      inv.inv_warehouse_sk
    FROM inventory_cte inv
    FULL OUTER JOIN sales s
      ON inv.i_item_id = s.i_item_id
  )
SELECT
  item_id,
  category_id,
  SUM(COALESCE(ss_ext_sales_price, 0))                     AS total_sales,
  AVG(inv_quantity_on_hand)                               AS avg_inventory,
  SUM(COALESCE(ss_net_profit, 0))                         AS total_profit,
  CASE
    WHEN SUM(COALESCE(ss_net_profit, 0)) > 10000 THEN 'HIGH'
    WHEN SUM(COALESCE(ss_net_profit, 0)) > 1000  THEN 'MEDIUM'
    ELSE 'LOW'
  END                                                    AS profit_level,
  RANK() OVER (ORDER BY SUM(COALESCE(ss_net_profit, 0)) DESC) AS profit_rank
FROM full_join
GROUP BY
  item_id,
  category_id,
  inv_warehouse_sk
HAVING
  SUM(COALESCE(ss_ext_sales_price, 0)) > 500
  AND AVG(inv_quantity_on_hand) >= 150
ORDER BY profit_rank
LIMIT 100
