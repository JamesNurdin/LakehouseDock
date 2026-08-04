WITH common_items AS (
  SELECT ss.ss_item_sk AS item_sk
  FROM tpcds.store_sales ss TABLESAMPLE BERNOULLI (10)
  INTERSECT
  SELECT ws.ws_item_sk
  FROM tpcds.web_sales ws
),
store_part AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    i.i_category,
    d.d_date_sk AS sale_date_sk,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    CONCAT(i.i_brand, ' ', i.i_item_desc) AS item_full_desc,
    CASE WHEN regexp_like(i.i_item_desc, '\\d{2}') THEN 1 ELSE 0 END AS has_two_digits
  FROM tpcds.store_sales ss TABLESAMPLE BERNOULLI (5)
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_item_desc LIKE '%Large%'
    AND regexp_like(i.i_item_desc, 'Pack')
  GROUP BY ss.ss_item_sk, i.i_category, d.d_date_sk, i.i_brand, i.i_item_desc
),
web_part AS (
  SELECT
    ws.ws_item_sk AS item_sk,
    i.i_category,
    d.d_date_sk AS sale_date_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CONCAT(CAST(ws.ws_order_number AS varchar), '-', i.i_item_id) AS item_full_desc,
    CASE WHEN regexp_like(CAST(ws.ws_list_price AS varchar), '^9[0-9]') THEN 1 ELSE 0 END AS has_two_digits
  FROM tpcds.web_sales ws
  JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
  JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ws.ws_list_price > 50
    AND ws.ws_ext_sales_price IS NOT NULL
  GROUP BY ws.ws_item_sk, i.i_category, d.d_date_sk, ws.ws_order_number, i.i_item_id, ws.ws_list_price
),
union_agg AS (
  SELECT item_sk, i_category, sale_date_sk, total_sales, item_full_desc, has_two_digits
  FROM store_part
  UNION DISTINCT
  SELECT item_sk, i_category, sale_date_sk, total_sales, item_full_desc, has_two_digits
  FROM web_part
),
filtered_union AS (
  SELECT *
  FROM union_agg
  WHERE item_sk IN (SELECT item_sk FROM common_items)
),
date_sample AS (
  SELECT d_date_sk, d_date, d_year, d_month_seq
  FROM tpcds.date_dim
  TABLESAMPLE BERNOULLI (2)
)
SELECT
  fu.item_sk,
  fu.i_category,
  fu.sale_date_sk,
  fu.total_sales,
  fu.item_full_desc,
  fu.has_two_digits,
  ds.d_date,
  ds.d_year,
  ds.d_month_seq
FROM filtered_union fu
FULL OUTER JOIN date_sample ds
  ON fu.sale_date_sk = ds.d_date_sk
ORDER BY fu.total_sales DESC
LIMIT 100
