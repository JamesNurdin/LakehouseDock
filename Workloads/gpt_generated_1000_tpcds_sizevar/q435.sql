WITH
  ws_sample AS (
    SELECT
      ws_sold_date_sk,
      ws_item_sk,
      ws_quantity,
      ws_sales_price,
      ARRAY[ws_quantity] AS qty_arr,
      ARRAY[ws_sales_price] AS price_arr
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk
      FROM tpcds.date_dim
      WHERE d_year = 2001
    )
  ),
  ws_exploded AS (
    SELECT
      ws_sold_date_sk,
      ws_item_sk,
      q AS quantity,
      p AS price
    FROM ws_sample
    CROSS JOIN UNNEST(qty_arr, price_arr) AS t(q, p)
  ),
  sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(ws_exploded.price * ws_exploded.quantity) AS metric,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_exploded.price * ws_exploded.quantity) DESC) AS rank,
      'sales' AS source,
      (
        SELECT AVG(i2.i_current_price)
        FROM tpcds.item i2
        WHERE i2.i_category = i.i_category
      ) AS avg_category_price
    FROM ws_exploded
    JOIN tpcds.date_dim d ON ws_exploded.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws_exploded.ws_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost < 1.0
    GROUP BY d.d_year, i.i_category
    HAVING SUM(ws_exploded.price * ws_exploded.quantity) > 10000
  ),
  cr_sample AS (
    SELECT
      cr_returned_date_sk,
      cr_item_sk,
      cr_return_quantity,
      cr_return_amount
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_returned_date_sk IN (
      SELECT d_date_sk
      FROM tpcds.date_dim
      WHERE d_year = 2001
    )
  ),
  returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(cr_sample.cr_return_amount) AS metric,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr_sample.cr_return_amount) DESC) AS rank,
      'returns' AS source,
      (
        SELECT AVG(i2.i_current_price)
        FROM tpcds.item i2
        WHERE i2.i_category = i.i_category
      ) AS avg_category_price
    FROM cr_sample
    JOIN tpcds.date_dim d ON cr_sample.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cr_sample.cr_item_sk = i.i_item_sk
    WHERE EXISTS (
      SELECT 1
      FROM tpcds.web_site ws
      WHERE ws.web_site_sk = 1
    )
    GROUP BY d.d_year, i.i_category
    HAVING SUM(cr_sample.cr_return_amount) > 5000
  )
SELECT
  year,
  category,
  metric,
  rank,
  source,
  avg_category_price
FROM sales_agg
UNION ALL
SELECT
  year,
  category,
  metric,
  rank,
  source,
  avg_category_price
FROM returns_agg
ORDER BY year DESC, metric DESC
LIMIT 100
