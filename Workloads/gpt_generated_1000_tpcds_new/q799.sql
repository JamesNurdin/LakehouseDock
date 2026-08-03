WITH
  store_item_sales AS (
    SELECT
      ss.ss_item_sk AS item_sk,
      SUM(ss.ss_ext_sales_price) AS store_sales,
      CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_item_sk
  ),
  web_item_sales AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales,
      CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_item_sk
  ),
  combined_sales AS (
    SELECT
      COALESCE(s.item_sk, w.item_sk) AS item_sk,
      s.store_sales,
      w.web_sales,
      CASE
        WHEN COALESCE(s.store_sales, 0) > COALESCE(w.web_sales, 0) THEN 'StoreHigher'
        WHEN COALESCE(s.store_sales, 0) < COALESCE(w.web_sales, 0) THEN 'WebHigher'
        ELSE 'Equal'
      END AS higher_source
    FROM store_item_sales s
    FULL OUTER JOIN web_item_sales w
      ON s.item_sk = w.item_sk
  ),
  union_sales AS (
    SELECT item_sk, store_sales AS sales_amount, 'Store' AS source FROM store_item_sales
    UNION
    SELECT item_sk, web_sales AS sales_amount, 'Web' AS source FROM web_item_sales
  ),
  filtered_union AS (
    SELECT *
    FROM union_sales
    WHERE sales_amount > 1000
  ),
  except_set AS (
    SELECT item_sk FROM filtered_union
    EXCEPT
    SELECT item_sk FROM combined_sales WHERE higher_source = 'StoreHigher'
  )
SELECT
  e.item_sk,
  i.i_product_name,
  ROW_NUMBER() OVER (ORDER BY e.item_sk) AS rn
FROM except_set e
JOIN item i ON e.item_sk = i.i_item_sk
ORDER BY rn
LIMIT 100
