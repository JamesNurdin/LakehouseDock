/*
Goal: Identify high‑price items (current price > 100) that have a Spring‑related promotion and that generated a total net profit higher than the average store‑sale net profit. The query combines store and web sales using UNION ALL, applies DISTINCT, uses a CTE for the high‑price items, includes EXISTS subqueries, and orders the results by total net profit.
*/
WITH high_price_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_product_name,
           i_current_price
    FROM   item
    WHERE  i_current_price > 100
)
SELECT   combined.item_id,
         combined.product_name,
         SUM(combined.net_profit) AS total_net_profit
FROM (
    SELECT DISTINCT i.i_item_id   AS item_id,
                    i.i_product_name AS product_name,
                    ss.ss_net_profit  AS net_profit
    FROM   store_sales ss
    JOIN   high_price_items h   ON ss.ss_item_sk = h.i_item_sk
    JOIN   item i               ON ss.ss_item_sk = i.i_item_sk
    WHERE  i.i_rec_start_date > DATE '2000-01-01'
      AND EXISTS (
          SELECT 1
          FROM   promotion p
          WHERE  p.p_item_sk = i.i_item_sk
            AND  p.p_promo_name LIKE '%Spring%'
      )
    UNION ALL
    SELECT DISTINCT i.i_item_id   AS item_id,
                    i.i_product_name AS product_name,
                    ws.ws_net_profit  AS net_profit
    FROM   web_sales ws
    JOIN   high_price_items h   ON ws.ws_item_sk = h.i_item_sk
    JOIN   item i               ON ws.ws_item_sk = i.i_item_sk
    WHERE  i.i_rec_start_date > DATE '2000-01-01'
      AND EXISTS (
          SELECT 1
          FROM   promotion p
          WHERE  p.p_item_sk = i.i_item_sk
            AND  p.p_promo_name LIKE '%Spring%'
      )
) AS combined
GROUP BY combined.item_id, combined.product_name
HAVING SUM(combined.net_profit) > (
    SELECT AVG(ss2.ss_net_profit)
    FROM   store_sales ss2
)
ORDER BY total_net_profit DESC
LIMIT 100
