WITH ss_agg AS (
   SELECT
      ss_item_sk,
      ss_sold_date_sk,
      ss_cdemo_sk,
      SUM(ss_quantity) AS total_quantity,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_profit
   FROM store_sales
   WHERE ss_quantity > 0
   GROUP BY ss_item_sk, ss_sold_date_sk, ss_cdemo_sk
)
SELECT
   d.d_year,
   i.i_category,
   i.i_brand,
   cp.cp_department,
   SUM(ssa.total_sales) AS year_category_sales,
   SUM(ssa.total_profit) AS year_category_profit,
   COUNT(DISTINCT cp.cp_catalog_page_number) AS distinct_pages,
   CASE
      WHEN SUM(ssa.total_sales) > 1000000 THEN 'HIGH'
      ELSE 'NORMAL'
   END AS sales_level
FROM ss_agg ssa
JOIN date_dim d
  ON ssa.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ssa.ss_item_sk = i.i_item_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
  AND p.p_start_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON ssa.ss_cdemo_sk = cd.cd_demo_sk
WHERE
   d.d_year BETWEEN 1998 AND 2000
   AND i.i_brand_id IN (1, 2, 3)
   AND cp.cp_department = 'Books'
   AND cd.cd_marital_status = 'M'
   AND p.p_discount_active = 'Y'
   AND EXISTS (
       SELECT 1 FROM promotion p2
       WHERE p2.p_item_sk = i.i_item_sk
         AND p2.p_start_date_sk = d.d_date_sk
         AND p2.p_channel_tv = 'N'
   )
GROUP BY d.d_year, i.i_category, i.i_brand, cp.cp_department
HAVING SUM(ssa.total_quantity) > 5000
ORDER BY year_category_sales DESC
LIMIT 100
