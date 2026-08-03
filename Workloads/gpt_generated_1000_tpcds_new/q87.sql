WITH sales_agg AS (
  SELECT
    d.d_year,
    i.i_item_sk,
    i.i_product_name,
    regexp_extract(i.i_product_name, '^(\\w+)', 1) AS product_prefix,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_qty
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_description LIKE '%Season%'
    AND regexp_like(i.i_product_name, '^\\w+-')
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_item_sk, i.i_product_name, regexp_extract(i.i_product_name, '^(\\w+)', 1)
),
ranked_sales AS (
  SELECT
    s.*, 
    row_number() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS rnk
  FROM sales_agg s
),
top_sales AS (
  SELECT d_year, i_item_sk, i_product_name, total_sales, total_qty
  FROM ranked_sales
  WHERE rnk <= 5
),
returns_items AS (
  SELECT DISTINCT sr.sr_item_sk AS i_item_sk
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
),
final_items AS (
  SELECT d_year, i_item_sk, i_product_name, total_sales, total_qty
  FROM top_sales
  EXCEPT
  SELECT ts.d_year, ri.i_item_sk, ts.i_product_name, CAST(0 AS decimal(7,2)), 0
  FROM returns_items ri
  JOIN top_sales ts ON ri.i_item_sk = ts.i_item_sk
)
SELECT
  d_year,
  i_item_sk,
  i_product_name,
  total_sales,
  total_qty,
  concat(i_product_name, ' - ', CAST(total_sales AS varchar)) AS label
FROM final_items
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
