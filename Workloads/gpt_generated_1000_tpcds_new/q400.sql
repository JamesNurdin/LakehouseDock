WITH
  avg_price AS (
    SELECT AVG(i2.i_current_price) AS avg_price
    FROM item i2
  ),
  sold_items AS (
    SELECT DISTINCT
      ss.ss_item_sk AS item_sk,
      i.i_item_id AS item_id,
      i.i_current_price AS current_price,
      CASE WHEN i.i_current_price > (SELECT avg_price FROM avg_price) THEN 'Above Avg' ELSE 'Below Avg' END AS price_vs_avg,
      CASE WHEN i.i_current_price > 100 THEN 'High' ELSE 'Low' END AS price_tier,
      s.s_store_id AS location
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450836 AND 2451067
      AND s.s_state = 'CA'
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
  ),
  returned_items AS (
    SELECT DISTINCT
      cr.cr_item_sk AS item_sk,
      i.i_item_id AS item_id,
      i.i_current_price AS current_price,
      CASE WHEN i.i_current_price > (SELECT avg_price FROM avg_price) THEN 'Above Avg' ELSE 'Below Avg' END AS price_vs_avg,
      CASE WHEN i.i_current_price > 100 THEN 'High' ELSE 'Low' END AS price_tier,
      cc.cc_name AS location
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450836 AND 2451067
      AND cr.cr_return_amount > 0
  )
SELECT
  item_sk,
  item_id,
  current_price,
  price_vs_avg,
  price_tier,
  location
FROM sold_items
EXCEPT
SELECT
  item_sk,
  item_id,
  current_price,
  price_vs_avg,
  price_tier,
  location
FROM returned_items
ORDER BY current_price DESC
LIMIT 100
