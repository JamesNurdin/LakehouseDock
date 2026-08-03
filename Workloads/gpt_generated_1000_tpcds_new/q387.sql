WITH sales_items AS (
  SELECT i.i_item_id AS id,
         d.d_year,
         SUM(cs.cs_quantity) AS total_qty,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         ARRAY[SUM(cs.cs_quantity), SUM(cs.cs_ext_sales_price)] AS qty_sales_arr
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, d.d_year
),
returns_items AS (
  SELECT i.i_item_id AS id,
         d.d_year,
         SUM(wr.wr_return_amt) AS total_returns
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, d.d_year
),
sales_without_returns AS (
  SELECT s.id,
         s.d_year,
         s.total_sales,
         s.qty_sales_arr
  FROM sales_items s
  EXCEPT
  SELECT r.id,
         r.d_year,
         r.total_returns,
         CAST(NULL AS array(decimal(7,2)))
  FROM returns_items r
),
store_warehouse_full AS (
  SELECT s.s_store_id   AS id,
         s.s_city       AS city,
         'store'        AS entity_type,
         s.s_number_employees AS metric_value
  FROM store s
  FULL OUTER JOIN warehouse w ON s.s_city = w.w_city
  WHERE s.s_closed_date_sk IS NULL

  UNION ALL

  SELECT w.w_warehouse_id AS id,
         w.w_city        AS city,
         'warehouse'     AS entity_type,
         w.w_warehouse_sq_ft AS metric_value
  FROM store s
  FULL OUTER JOIN warehouse w ON s.s_city = w.w_city
  WHERE s.s_closed_date_sk IS NOT NULL OR s.s_store_id IS NULL
),
final_sales AS (
  SELECT 'item'   AS entity_type,
         swr.id   AS id,
         NULL     AS city,
         swr.total_sales AS metric_value
  FROM sales_without_returns swr
  CROSS JOIN LATERAL (
    SELECT elem[1] AS qty,
           elem[2] AS price
    FROM UNNEST(ARRAY[ swr.qty_sales_arr ]) AS t(elem)
  ) l
)
SELECT entity_type,
       id,
       city,
       metric_value
FROM (
  SELECT entity_type, id, city, metric_value FROM store_warehouse_full
  UNION
  SELECT entity_type, id, city, metric_value FROM final_sales
) combined
ORDER BY entity_type,
         metric_value DESC
LIMIT 100
