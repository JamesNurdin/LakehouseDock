/* goal: Compare yearly return amounts and web sales profits for items matching specific naming patterns, filtered by category and warehouse location, while excluding low‑value return rows */
WITH
sampled_items AS (
  SELECT i_item_sk,
         i_product_name,
         i_category,
         i_current_price
  FROM item TABLESAMPLE BERNOULLI (10)
),
return_agg AS (
  SELECT
    d.d_year AS year,
    'return' AS metric_type,
    SUM(cr.cr_return_amount) AS metric_value,
    REGEXP_EXTRACT(i.i_product_name, '^(\\w+)-', 1) AS product_prefix
  FROM catalog_returns cr
  JOIN sampled_items i ON cr.cr_item_sk = i.i_item_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE REGEXP_LIKE(i.i_product_name, '^.*-A[0-9]{3}$')
    AND i.i_category LIKE '%Electronics%'
    AND EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%defect%'
    )
  GROUP BY d.d_year,
           REGEXP_EXTRACT(i.i_product_name, '^(\\w+)-', 1)
),
sales_agg AS (
  SELECT
    d.d_year AS year,
    'profit' AS metric_type,
    SUM(ws.ws_net_profit) AS metric_value,
    SUBSTRING(i.i_product_name, 1, 5) AS product_prefix
  FROM web_sales ws
  JOIN sampled_items i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE i.i_product_name LIKE '%-B%'
    AND REGEXP_LIKE(i.i_product_name, '.*[0-9]{2}$')
    AND ws.ws_warehouse_sk IN (
        SELECT w_warehouse_sk FROM warehouse WHERE w_city LIKE 'San%'
    )
  GROUP BY d.d_year,
           SUBSTRING(i.i_product_name, 1, 5)
),
combined AS (
  SELECT year, metric_type, metric_value, product_prefix FROM return_agg
  UNION DISTINCT
  SELECT year, metric_type, metric_value, product_prefix FROM sales_agg
)
SELECT year, metric_type, metric_value, product_prefix
FROM combined
EXCEPT
SELECT year, metric_type, metric_value, product_prefix
FROM combined
WHERE metric_type = 'return' AND metric_value < 1000
ORDER BY year, metric_type
