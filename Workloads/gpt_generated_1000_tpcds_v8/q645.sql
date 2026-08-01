/* goal: Identify the top-selling items in 2000 across catalog and store channels, rank them within each product category, attach a constant total‑item count via a cross join, exclude any items that have been returned, and present the combined distinct result ordered by revenue */
WITH recent_dates AS (
   SELECT d_date_sk
   FROM date_dim
   WHERE d_year = 2000
),
cross_info AS (
   SELECT d.d_date_sk, ti.total_items
   FROM (SELECT d_date_sk FROM date_dim WHERE d_year = 2000 LIMIT 1) d
   CROSS JOIN (SELECT COUNT(*) AS total_items FROM item) ti
),
catalog_agg AS (
   SELECT
       'catalog' AS sales_source,
       i.i_item_sk,
       i.i_product_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS category_rank,
       ci.total_items
   FROM catalog_sales cs
   JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   CROSS JOIN cross_info ci
   WHERE i.i_item_sk NOT IN (SELECT wr.wr_item_sk FROM web_returns wr WHERE wr.wr_return_amt > 0)
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, ci.total_items
),
store_agg AS (
   SELECT
       'store' AS sales_source,
       i.i_item_sk,
       i.i_product_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS category_rank,
       ci.total_items
   FROM store_sales ss
   JOIN recent_dates rd ON ss.ss_sold_date_sk = rd.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   CROSS JOIN cross_info ci
   WHERE i.i_item_sk NOT IN (SELECT wr.wr_item_sk FROM web_returns wr WHERE wr.wr_return_amt > 0)
   GROUP BY i.i_item_sk, i.i_product_name, i.i_category, ci.total_items
)
SELECT *
FROM (
   SELECT sales_source, i_item_sk, i_product_name, total_sales, category_rank, total_items
   FROM catalog_agg
   UNION
   SELECT sales_source, i_item_sk, i_product_name, total_sales, category_rank, total_items
   FROM store_agg
) final_result
ORDER BY total_sales DESC
LIMIT 100
