WITH
  returns_morning AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      i.i_category AS category,
      SUM(cr.cr_return_amount) AS total_amount,
      'return' AS source
    FROM catalog_returns AS cr
    JOIN item AS i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim AS t
      ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND i.i_class = 'scanners'
    GROUP BY cr.cr_returned_date_sk, i.i_category
  ),
  sales_morning AS (
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      i.i_category AS category,
      SUM(ws.ws_ext_sales_price) AS total_amount,
      'sale' AS source
    FROM web_sales AS ws
    JOIN item AS i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim AS t
      ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND i.i_class = 'pants'
    GROUP BY ws.ws_sold_date_sk, i.i_category
  )
SELECT date_sk, category, total_amount, source
FROM returns_morning
UNION ALL
SELECT date_sk, category, total_amount, source
FROM sales_morning
ORDER BY date_sk, category, source
LIMIT 100
