WITH sales AS (
   SELECT
       s.s_store_name AS store_name,
       d.d_year AS year,
       i.i_category AS category,
       i.i_item_desc AS item_desc,
       SUM(ss.ss_ext_sales_price) AS metric,
       'sales' AS metric_type,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '.*[0-9]{2}.*')
     AND s.s_city LIKE 'San %'
   GROUP BY s.s_store_name, d.d_year, i.i_category, i.i_item_desc
   HAVING SUM(ss.ss_ext_sales_price) > 10000
),
returns AS (
   SELECT
       s.s_store_name AS store_name,
       d.d_year AS year,
       i.i_category AS category,
       i.i_item_desc AS item_desc,
       SUM(sr.sr_return_amt_inc_tax) AS metric,
       'returns' AS metric_type,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS rn
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '.*[0-9]{2}.*')
     AND s.s_city LIKE 'San %'
   GROUP BY s.s_store_name, d.d_year, i.i_category, i.i_item_desc
   HAVING SUM(sr.sr_return_amt_inc_tax) > 5000
)
SELECT
    store_name,
    year,
    category,
    metric,
    metric_type,
    rn,
    concat(substr(store_name, 1, 3), '-', cast(year AS varchar)) AS store_year_key,
    regexp_extract(item_desc, '\\d+', 0) AS first_number_in_desc
FROM (
   SELECT store_name, year, category, metric, metric_type, rn, item_desc FROM sales
   UNION ALL
   SELECT store_name, year, category, metric, metric_type, rn, item_desc FROM returns
) t
ORDER BY metric DESC
LIMIT 100
