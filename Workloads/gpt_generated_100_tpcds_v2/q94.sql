WITH
  item_filtered AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           i.i_class
    FROM item i
    WHERE i.i_rec_start_date <= DATE '2022-12-31'
      AND i.i_rec_end_date >= DATE '2022-01-01'
      AND i.i_class IN ('maternity', 'costume', 'dresses')
  ),
  store_agg AS (
    SELECT ss.ss_item_sk AS i_item_sk,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  web_agg AS (
    SELECT ws.ws_item_sk AS i_item_sk,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
  ),
  inventory_agg AS (
    SELECT inv.inv_item_sk AS i_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
  ),
  joined AS (
    SELECT f.i_item_sk,
           f.i_item_id,
           f.i_product_name,
           f.i_category,
           f.i_brand,
           f.i_class,
           COALESCE(sa.store_quantity, 0) AS store_quantity,
           COALESCE(sa.store_net_profit, 0) AS store_net_profit,
           COALESCE(wa.web_quantity, 0) AS web_quantity,
           COALESCE(wa.web_net_profit, 0) AS web_net_profit,
           COALESCE(ia.total_on_hand, 0) AS total_on_hand
    FROM item_filtered f
    LEFT JOIN store_agg sa ON sa.i_item_sk = f.i_item_sk
    LEFT JOIN web_agg wa ON wa.i_item_sk = f.i_item_sk
    LEFT JOIN inventory_agg ia ON ia.i_item_sk = f.i_item_sk
    WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
  )
SELECT j.i_item_id,
       j.i_product_name,
       j.i_category,
       j.i_brand,
       j.i_class,
       (j.store_quantity + j.web_quantity) AS total_quantity_sold,
       (j.store_net_profit + j.web_net_profit) AS total_net_profit,
       j.total_on_hand,
       CASE WHEN j.total_on_hand > 0 THEN (j.store_net_profit + j.web_net_profit) / j.total_on_hand ELSE NULL END AS profit_per_inventory_unit,
       ROW_NUMBER() OVER (ORDER BY (j.store_net_profit + j.web_net_profit) DESC) AS profit_rank
FROM joined j
ORDER BY total_net_profit DESC
LIMIT 20
