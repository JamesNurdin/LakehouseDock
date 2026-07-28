WITH
  item_inventory AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_current_price,
           inv.inv_quantity_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0
  ),
  store_returns_agg AS (
    SELECT ii.i_item_sk,
           ii.i_product_name,
           ii.i_category,
           SUM(sr.sr_return_amt) AS total_return,
           COUNT(*) AS return_cnt,
           ROW_NUMBER() OVER (PARTITION BY ii.i_category ORDER BY SUM(sr.sr_return_amt) DESC) AS rn_cat
    FROM item_inventory ii
    JOIN store_returns sr ON sr.sr_item_sk = ii.i_item_sk
    GROUP BY ii.i_item_sk, ii.i_product_name, ii.i_category
    HAVING SUM(sr.sr_return_amt) > 0
  ),
  web_returns_agg AS (
    SELECT ii.i_item_sk,
           ii.i_product_name,
           ii.i_category,
           SUM(wr.wr_return_amt) AS total_return,
           COUNT(*) AS return_cnt,
           ROW_NUMBER() OVER (PARTITION BY ii.i_category ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_cat
    FROM item_inventory ii
    JOIN web_returns wr ON wr.wr_item_sk = ii.i_item_sk
    GROUP BY ii.i_item_sk, ii.i_product_name, ii.i_category
    HAVING SUM(wr.wr_return_amt) > 0
  )
SELECT
  'store' AS channel,
  sra.i_item_sk,
  sra.i_product_name,
  sra.i_category,
  sra.total_return,
  sra.return_cnt,
  CASE WHEN sra.total_return > 500 THEN 'high' ELSE 'low' END AS return_level,
  sra.rn_cat
FROM store_returns_agg sra
WHERE NOT EXISTS (
  SELECT 1 FROM web_returns_agg wra WHERE wra.i_item_sk = sra.i_item_sk
)
UNION ALL
SELECT
  'web' AS channel,
  wra.i_item_sk,
  wra.i_product_name,
  wra.i_category,
  wra.total_return,
  wra.return_cnt,
  CASE WHEN wra.total_return > 500 THEN 'high' ELSE 'low' END AS return_level,
  wra.rn_cat
FROM web_returns_agg wra
WHERE NOT EXISTS (
  SELECT 1 FROM store_returns_agg sra2 WHERE sra2.i_item_sk = wra.i_item_sk
)
ORDER BY total_return DESC
LIMIT 100
