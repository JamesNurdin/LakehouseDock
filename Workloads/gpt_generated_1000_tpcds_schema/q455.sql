WITH
  -- Sample a fraction of the raw fact tables
  store_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  web_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Pre‑aggregate store sales per item / household
  store_agg AS (
    SELECT
      ss_item_sk,
      ss_hdemo_sk,
      SUM(ss_ext_sales_price)               AS total_store_sales,
      COUNT(*)                              AS store_txn_cnt,
      ARRAY_AGG(ss_sales_price)             AS store_price_array
    FROM store_sample
    WHERE ss_sales_price        > 0
      AND ss_wholesale_cost    < 100
      AND ss_coupon_amt        < 5000
      AND ss_quantity          >= 1
    GROUP BY ss_item_sk, ss_hdemo_sk
  ),
  -- Pre‑aggregate web sales per item / billing household
  web_agg AS (
    SELECT
      ws_item_sk,
      ws_bill_hdemo_sk,
      SUM(ws_ext_sales_price)               AS total_web_sales,
      COUNT(*)                              AS web_txn_cnt,
      ARRAY_AGG(ws_sales_price)             AS web_price_array
    FROM web_sample
    WHERE ws_sales_price        > 0
      AND ws_wholesale_cost    < 100
      AND ws_coupon_amt        < 5000
      AND ws_quantity          >= 1
    GROUP BY ws_item_sk, ws_bill_hdemo_sk
  ),
  -- A filtered view of the item dimension
  item_filtered AS (
    SELECT *
    FROM item
    WHERE i_current_price BETWEEN 5 AND 200
      AND i_wholesale_cost   < 50
      AND i_category_id IN (1, 4, 6, 7, 10)
      AND i_brand IS NOT NULL
  ),
  -- Sets used for the EXCEPT operation
  store_high AS (
    SELECT ss_item_sk AS item_sk
    FROM store_agg
    WHERE total_store_sales > 10000
  ),
  web_high AS (
    SELECT ws_item_sk AS item_sk
    FROM web_agg
    WHERE total_web_sales > 10000
  ),
  -- Items that are high in store sales but not high in web sales
  final_items AS (
    SELECT sh.item_sk
    FROM store_high sh
    EXCEPT
    SELECT wh.item_sk
    FROM web_high wh
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_category,
  hd.hd_buy_potential,
  sa.total_store_sales,
  wa.total_web_sales,
  ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY sa.total_store_sales DESC) AS rn_category_store,
  sp.avg_price      AS avg_store_price,
  wp.avg_price      AS avg_web_price
FROM final_items fi
JOIN store_agg sa ON fi.item_sk = sa.ss_item_sk
JOIN web_agg   wa ON fi.item_sk = wa.ws_item_sk
JOIN item      i  ON i.i_item_sk = fi.item_sk
JOIN household_demographics hd ON hd.hd_demo_sk = sa.ss_hdemo_sk
-- LATERAL subquery to unnest the store price array and compute an average
LEFT JOIN LATERAL (
  SELECT AVG(p) AS avg_price
  FROM UNNEST(sa.store_price_array) AS t(p)
) sp ON TRUE
-- LATERAL subquery to unnest the web price array and compute an average
LEFT JOIN LATERAL (
  SELECT AVG(p) AS avg_price
  FROM UNNEST(wa.web_price_array) AS t(p)
) wp ON TRUE
-- Anti‑join: keep rows where no store transaction has a huge coupon amount
WHERE NOT EXISTS (
  SELECT 1
  FROM store_sales ss2
  WHERE ss2.ss_item_sk = i.i_item_sk
    AND ss2.ss_coupon_amt > 4000
)
ORDER BY sa.total_store_sales DESC, rn_category_store
LIMIT 100
