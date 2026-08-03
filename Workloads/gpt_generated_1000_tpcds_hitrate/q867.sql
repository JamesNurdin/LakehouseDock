WITH filtered_items AS (
   SELECT i_item_sk, i_category, i_class_id
   FROM item
   WHERE i_class_id IN (1, 3, 12)
)
SELECT *
FROM (
   SELECT
      'catalog' AS sales_channel,
      d.d_year,
      f.i_category,
      CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      (SELECT AVG(cs_sub.cs_ext_sales_price) FROM catalog_sales cs_sub) AS overall_avg_price
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN filtered_items f
     ON cs.cs_item_sk = f.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
     AND f.i_category IN (SELECT i_category FROM item WHERE i_class_id = 14)
   GROUP BY d.d_year, f.i_category
   HAVING SUM(cs.cs_ext_sales_price) > 5000

   UNION ALL

   SELECT
      'store' AS sales_channel,
      d.d_year,
      f.i_category,
      CASE WHEN SUM(ss.ss_net_profit) > 8000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      (SELECT AVG(ss_sub.ss_ext_sales_price) FROM store_sales ss_sub) AS overall_avg_price
   FROM store_sales ss
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN filtered_items f
     ON ss.ss_item_sk = f.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
     AND EXISTS (
          SELECT 1 FROM household_demographics hd
          WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
            AND hd.hd_vehicle_count > 1
     )
   GROUP BY d.d_year, f.i_category
   HAVING SUM(ss.ss_ext_sales_price) > 5000
) combined
LIMIT 100
