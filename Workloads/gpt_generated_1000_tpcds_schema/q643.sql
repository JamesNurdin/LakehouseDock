WITH
  sampled_store_sales AS (
    SELECT
      ss_item_sk,
      SUM(ss_ext_sales_price) AS store_sales_total
    FROM store_sales TABLESAMPLE BERNOULLI (5)
    GROUP BY ss_item_sk
  ),
  sampled_web_sales AS (
    SELECT
      ws_item_sk,
      SUM(ws_ext_sales_price) AS web_sales_total
    FROM web_sales TABLESAMPLE BERNOULLI (5)
    GROUP BY ws_item_sk
  ),
  full_aggregated AS (
    SELECT
      COALESCE(s.ss_item_sk, w.ws_item_sk) AS item_sk,
      COALESCE(s.store_sales_total, 0)      AS store_sales,
      COALESCE(w.web_sales_total, 0)       AS web_sales,
      CASE
        WHEN COALESCE(s.store_sales_total, 0) > COALESCE(w.web_sales_total, 0) THEN 'Store'
        ELSE 'Web'
      END                                 AS top_channel
    FROM sampled_store_sales s
    FULL OUTER JOIN sampled_web_sales w
      ON s.ss_item_sk = w.ws_item_sk
  ),
  high_sales_items AS (
    SELECT DISTINCT ss_item_sk AS item_sk
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
  ),
  high_return_items AS (
    SELECT DISTINCT sr_item_sk AS item_sk
    FROM store_returns
    WHERE sr_return_amt > 500
  ),
  intersect_items AS (
    SELECT item_sk FROM high_sales_items
    INTERSECT
    SELECT item_sk FROM high_return_items
  ),
  top_items AS (
    SELECT
      f.item_sk,
      i.i_product_name,
      f.store_sales,
      f.web_sales,
      f.top_channel,
      'Aggregated' AS source
    FROM full_aggregated f
    JOIN item i
      ON f.item_sk = i.i_item_sk
    WHERE f.store_sales > 0 OR f.web_sales > 0
  ),
  intersect_detail AS (
    SELECT
      ii.item_sk,
      i.i_product_name,
      0.0 AS store_sales,
      0.0 AS web_sales,
      'BothHigh' AS top_channel,
      'Intersect' AS source
    FROM intersect_items ii
    JOIN item i
      ON ii.item_sk = i.i_item_sk
  )
SELECT *
FROM top_items
UNION ALL
SELECT *
FROM intersect_detail
ORDER BY (store_sales + web_sales) DESC
OFFSET 10 ROWS FETCH NEXT 30 ROWS ONLY
