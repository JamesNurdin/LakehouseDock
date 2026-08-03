WITH combined_sales AS (
   SELECT
      i.i_item_id      AS loc_id,
      'item'           AS loc_type,
      d.d_year         AS year,
      cs.cs_order_number AS order_number,
      cs.cs_ext_sales_price AS sales_amount,
      CASE WHEN cs.cs_ext_sales_price > 1000 THEN 1 ELSE 0 END AS high_price_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_class = 'shirts'
   UNION ALL
   SELECT
      w.w_warehouse_id AS loc_id,
      'warehouse'      AS loc_type,
      d.d_year         AS year,
      cs.cs_order_number AS order_number,
      cs.cs_ext_sales_price AS sales_amount,
      CASE WHEN cs.cs_ext_sales_price > 1000 THEN 1 ELSE 0 END AS high_price_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND w.w_city = 'Boston'
)
SELECT
   year,
   COUNT(DISTINCT loc_id)          AS distinct_locations,
   COUNT(DISTINCT order_number)   AS distinct_orders,
   SUM(DISTINCT sales_amount)     AS sum_distinct_sales,
   SUM(high_price_flag)           AS high_price_transactions
FROM combined_sales
GROUP BY year
ORDER BY year DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
