WITH
  sampled_items AS (
    SELECT i_item_sk, i_product_name, i_current_price
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (5)   -- sample ~5% of rows
  ),

  -- Store sales aggregated per item
  store_sales_pre AS (
    SELECT ss.ss_item_sk,
           ss.ss_sold_date_sk,
           ss.ss_ext_sales_price
    FROM tpcds.store_sales ss
    JOIN sampled_items i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2452151 AND 2452556
  ),
  store_sales_agg AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price)                     AS store_total_sales,
           MIN(ss_sold_date_sk)                        AS first_sold_date_sk,
           COUNT(*)                                    AS store_transactions
    FROM store_sales_pre
    GROUP BY ss_item_sk
  ),
  store_sales_lag AS (
    SELECT ss_item_sk,
           store_total_sales,
           store_transactions,
           LAG(store_total_sales) OVER (PARTITION BY ss_item_sk ORDER BY first_sold_date_sk) AS prev_store_sales
    FROM store_sales_agg
  ),

  -- Web sales aggregated per item
  web_sales_pre AS (
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           ws.ws_ext_sales_price
    FROM tpcds.web_sales ws
    JOIN sampled_items i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2452151 AND 2452556
  ),
  web_sales_agg AS (
    SELECT ws_item_sk,
           SUM(ws_ext_sales_price) AS web_total_sales,
           COUNT(*)               AS web_transactions
    FROM web_sales_pre
    GROUP BY ws_item_sk
  ),

  -- Simple key lists for set operations
  store_items AS (
    SELECT DISTINCT ss_item_sk AS item_sk
    FROM tpcds.store_sales
    WHERE ss_sold_date_sk BETWEEN 2452151 AND 2452556
  ),
  web_items AS (
    SELECT DISTINCT ws_item_sk AS item_sk
    FROM tpcds.web_sales
    WHERE ws_sold_date_sk BETWEEN 2452151 AND 2452556
  ),
  catalog_items AS (
    SELECT DISTINCT cs_item_sk AS item_sk
    FROM tpcds.catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2452151 AND 2452556
  )

SELECT DISTINCT
  i.i_item_sk,
  i.i_product_name,
  s.store_total_sales,
  w.web_total_sales,
  s.prev_store_sales,
  (SELECT AVG(i_current_price) FROM sampled_items) AS avg_price_sampled
FROM sampled_items i
JOIN store_sales_lag s ON i.i_item_sk = s.ss_item_sk
LEFT JOIN web_sales_agg w ON i.i_item_sk = w.ws_item_sk
WHERE i.i_item_sk IN (
      SELECT item_sk FROM (
        SELECT item_sk FROM store_items
        EXCEPT
        SELECT item_sk FROM web_items
      ) AS only_store
      INTERSECT
      SELECT item_sk FROM catalog_items
    )
ORDER BY s.store_total_sales DESC
LIMIT 100
