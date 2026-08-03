WITH
  store_item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      COUNT(*) AS store_txn_cnt,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_item_id LIKE 'A%'
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING SUM(ss.ss_ext_sales_price) > 0
  ),
  web_item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      COUNT(*) AS web_txn_cnt,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)steel')
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING COUNT(*) >= 1
  ),
  intersect_items AS (
    SELECT i_item_sk FROM store_item_sales
    INTERSECT
    SELECT i_item_sk FROM web_item_sales
  ),
  full_join_sales AS (
    SELECT
      COALESCE(s.i_item_sk, w.i_item_sk) AS i_item_sk,
      COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
      s.store_sales_total,
      w.web_sales_total,
      CASE
        WHEN s.store_sales_total IS NULL THEN 'WEB_ONLY'
        WHEN w.web_sales_total IS NULL THEN 'STORE_ONLY'
        ELSE 'BOTH'
      END AS source_type
    FROM store_item_sales s
    FULL OUTER JOIN web_item_sales w
      ON s.i_item_sk = w.i_item_sk
  )
SELECT
  f.i_item_id,
  f.i_item_sk,
  f.store_sales_total,
  f.web_sales_total,
  f.source_type,
  CASE
    WHEN f.store_sales_total IS NOT NULL AND f.web_sales_total IS NOT NULL
    THEN regexp_extract(f.i_item_id, '(\\d+)$')
    ELSE NULL
  END AS trailing_number
FROM full_join_sales f
WHERE f.i_item_id LIKE 'A%'
  AND f.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
ORDER BY f.i_item_sk
LIMIT 100
