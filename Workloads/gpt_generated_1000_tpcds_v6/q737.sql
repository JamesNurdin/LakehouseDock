WITH sales_by_store AS (
   SELECT
      s.s_store_id,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_class = 'dresses'
     AND d.d_weekend = 'N'
     AND s.s_rec_start_date <= DATE '2000-01-01'
     AND (s.s_rec_end_date IS NULL OR s.s_rec_end_date > DATE '2000-01-01')
   GROUP BY s.s_store_id, d.d_year, d.d_month_seq
   HAVING SUM(ss.ss_ext_sales_price) > 10000
)

SELECT
   combined.s_store_id,
   combined.d_year,
   combined.d_month_seq,
   combined.total_sales,
   combined.sales_cnt
FROM (
   SELECT s_store_id, d_year, d_month_seq, total_sales, sales_cnt
   FROM sales_by_store
   UNION ALL
   SELECT
      s.s_store_id,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_class = 'scanners'
     AND d.d_weekend = 'Y'
     AND s.s_geography_class = 'Unknown'
   GROUP BY s.s_store_id, d.d_year, d.d_month_seq
   HAVING SUM(ss.ss_ext_sales_price) > 5000
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
