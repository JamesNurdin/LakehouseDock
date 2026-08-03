WITH filtered_sales AS (
       SELECT ss.*
       FROM store_sales ss
       WHERE ss.ss_store_sk IN (
           SELECT s.s_store_sk
           FROM store s
           WHERE s.s_state = 'CA'
       )
   ),
   joined AS (
       SELECT
           d.d_year,
           i.i_category,
           i.i_item_id,
           i.i_item_desc,
           i.i_brand,
           regexp_extract(i.i_item_desc, '(Premium|Deluxe)', 1) AS matched_term,
           fs.ss_ext_sales_price
       FROM filtered_sales fs
       JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
       JOIN item i ON fs.ss_item_sk = i.i_item_sk
       WHERE regexp_like(i.i_item_desc, '(Premium|Deluxe)')
         AND i.i_brand LIKE 'A%'
   ),
   agg AS (
       SELECT
           d_year,
           i_category,
           i_item_id,
           i_item_desc,
           max(matched_term) AS matched_term,
           sum(ss_ext_sales_price) AS total_sales
       FROM joined
       GROUP BY d_year, i_category, i_item_id, i_item_desc
   ),
   ranked AS (
       SELECT
           d_year,
           i_category,
           i_item_id,
           i_item_desc,
           matched_term,
           total_sales,
           row_number() OVER (PARTITION BY d_year, i_category ORDER BY total_sales DESC) AS rk
       FROM agg
   )
SELECT
    d_year,
    i_category,
    i_item_id,
    i_item_desc,
    matched_term,
    total_sales,
    rk
FROM ranked
WHERE rk <= 5
ORDER BY d_year, i_category, rk
LIMIT 100
