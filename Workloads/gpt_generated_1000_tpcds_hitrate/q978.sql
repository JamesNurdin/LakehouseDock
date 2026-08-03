/*
Goal: Identify top customers and item categories by total profit, classifying profit levels, while demonstrating deep joins across all selected TPC‑DS tables, re‑using dimension tables under different aliases, expanding a derived array with UNNEST, applying a CASE expression, using an anti‑semi‑join via NOT IN, and aggregating with GROUPING SETS.
*/
WITH
  -- Base join of store_sales (the central fact) to its dimensions
  ss_join AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_net_profit AS ss_net_profit,
      i1.i_item_sk           AS i1_item_sk,
      i1.i_category,
      i1.i_class,
      c1.c_customer_id,
      hd1.hd_income_band_sk,
      ib1.ib_lower_bound,
      inv.inv_quantity_on_hand,
      ARRAY[i1.i_category, i1.i_class] AS cat_array
    FROM store_sales ss
    JOIN item i1
      ON ss.ss_item_sk = i1.i_item_sk
    JOIN customer c1
      ON ss.ss_customer_sk = c1.c_customer_sk
    JOIN household_demographics hd1
      ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN income_band ib1
      ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i1.i_item_sk
  ),
  -- Join of web_sales (second fact) re‑using item and customer under new aliases
  ws_join AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_net_profit AS ws_net_profit,
      i2.i_item_sk           AS i2_item_sk,
      i2.i_category          AS ws_category,
      c2.c_customer_id      AS ws_customer_id,
      hd2.hd_income_band_sk  AS ws_income_band_sk,
      ib2.ib_lower_bound    AS ws_lower_bound,
      wp.wp_web_page_id
    FROM web_sales ws
    JOIN item i2
      ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer c2
      ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2
      ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2
      ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
  )
SELECT
  sub.c_id,
  sub.category,
  SUM(sub.total_profit) AS sum_profit,
  CASE
    WHEN SUM(sub.total_profit) > 10000 THEN 'HIGH'
    WHEN SUM(sub.total_profit) > 0    THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_level,
  sub.cat_elem
FROM (
  SELECT
    c1.c_customer_id                     AS c_id,
    i1.i_category                        AS category,
    ss.ss_net_profit                     AS total_profit,
    cat_elem
  FROM store_sales ss
  JOIN item i1
    ON ss.ss_item_sk = i1.i_item_sk                -- join #1
  JOIN customer c1
    ON ss.ss_customer_sk = c1.c_customer_sk        -- join #2
  JOIN household_demographics hd1
    ON ss.ss_hdemo_sk = hd1.hd_demo_sk             -- join #3
  JOIN income_band ib1
    ON hd1.hd_income_band_sk = ib1.ib_income_band_sk -- join #4
  JOIN inventory inv
    ON inv.inv_item_sk = i1.i_item_sk               -- join #5
  -- expand a derived array containing category and class
  CROSS JOIN UNNEST(ARRAY[i1.i_category, i1.i_class]) AS t(cat_elem)    -- unnested array
  -- join the second fact table using the same item dimension but with a new alias
  JOIN web_sales ws
    ON ws.ws_item_sk = i1.i_item_sk                 -- join #6
  JOIN item i2
    ON ws.ws_item_sk = i2.i_item_sk                 -- join #7 (second alias of item)
  JOIN customer c2
    ON ws.ws_bill_customer_sk = c2.c_customer_sk   -- join #8 (second alias of customer)
  JOIN household_demographics hd2
    ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk        -- join #9
  JOIN income_band ib2
    ON hd2.hd_income_band_sk = ib2.ib_income_band_sk -- join #10
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk      -- join #11
  WHERE ss.ss_customer_sk NOT IN (
    SELECT ws2.ws_bill_customer_sk
    FROM web_sales ws2
    WHERE ws2.ws_net_profit > 0
  )                                                -- anti‑semi‑join subquery
) sub
GROUP BY GROUPING SETS (
  (c_id, category, cat_elem),
  (c_id, category),
  ()
)
ORDER BY sum_profit DESC
LIMIT 100
