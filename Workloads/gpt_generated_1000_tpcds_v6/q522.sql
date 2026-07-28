WITH store_part AS (
   SELECT ss.ss_sold_date_sk AS sales_date_sk,
          SUM(ss.ss_ext_sales_price) AS total_sales,
          (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_catalog_sales
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1 FROM inventory i
         WHERE i.inv_item_sk = ss.ss_item_sk
           AND i.inv_quantity_on_hand > 100
     )
   GROUP BY ss.ss_sold_date_sk
),
catalog_part AS (
   SELECT cs.cs_sold_date_sk AS sales_date_sk,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_catalog_sales
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE w.w_warehouse_sq_ft > 500000
   GROUP BY cs.cs_sold_date_sk
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM catalog_part
ORDER BY total_sales DESC
LIMIT 100
