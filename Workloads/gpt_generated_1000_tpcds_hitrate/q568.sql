WITH
  store_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      SUM(ss.ss_ext_sales_price) AS store_sales,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name
  ),
  web_sales_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name
  ),
  common_items AS (
    SELECT i_item_sk FROM store_sales_agg
    INTERSECT
    SELECT i_item_sk FROM web_sales_agg
  ),
  store_only_items AS (
    SELECT i_item_sk FROM store_sales_agg
    EXCEPT
    SELECT i_item_sk FROM web_sales_agg
  ),
  combined AS (
    SELECT
      s.i_item_sk,
      s.i_product_name,
      s.store_sales,
      COALESCE(w.web_sales, 0) AS web_sales,
      CASE
        WHEN w.i_item_sk IS NOT NULL THEN 'Both Channels'
        ELSE 'Store Only'
      END AS channel_scope,
      ROW_NUMBER() OVER (ORDER BY s.store_sales DESC) AS rn
    FROM store_sales_agg s
    LEFT JOIN web_sales_agg w ON s.i_item_sk = w.i_item_sk
    WHERE s.i_item_sk IN (
      SELECT i_item_sk FROM common_items
      UNION ALL
      SELECT i_item_sk FROM store_only_items
    )
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = s.i_item_sk
          AND p.p_cost > (
            SELECT AVG(p2.p_cost)
            FROM promotion p2
          )
      )
  )
SELECT
  rn,
  i_item_sk,
  i_product_name,
  store_sales,
  web_sales,
  channel_scope
FROM combined
ORDER BY rn
LIMIT 100
