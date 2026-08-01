WITH store_items AS (
   SELECT DISTINCT ss.ss_item_sk AS item_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
catalog_items AS (
   SELECT DISTINCT cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
common_items AS (
   SELECT item_sk FROM store_items
   INTERSECT
   SELECT item_sk FROM catalog_items
),
item_sales AS (
   SELECT i.i_item_sk,
          i.i_category,
          i.i_brand,
          SUM(ss.ss_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_item_sk IN (SELECT item_sk FROM common_items)
   GROUP BY CUBE (i.i_item_sk, i.i_category, i.i_brand)
),
promo_discount AS (
   SELECT i.i_item_sk,
          SUM(p.p_cost) AS total_promo_cost
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   WHERE i.i_item_sk IN (SELECT item_sk FROM common_items)
   GROUP BY i.i_item_sk
),
final_union AS (
   SELECT isales.i_item_sk,
          isales.i_category,
          isales.i_brand,
          isales.total_sales,
          isales.sales_cnt,
          pd.total_promo_cost
   FROM item_sales isales
   LEFT JOIN LATERAL (
       SELECT total_promo_cost
       FROM promo_discount pd
       WHERE pd.i_item_sk = isales.i_item_sk
   ) AS pd ON TRUE
   UNION
   SELECT isales.i_item_sk,
          isales.i_category,
          isales.i_brand,
          isales.total_sales,
          isales.sales_cnt,
          pd.total_promo_cost
   FROM item_sales isales
   LEFT JOIN LATERAL (
       SELECT total_promo_cost
       FROM promo_discount pd
       WHERE pd.i_item_sk = isales.i_item_sk
   ) AS pd ON TRUE
   WHERE isales.total_sales > 1000
)
SELECT fu.i_item_sk,
       fu.i_category,
       fu.i_brand,
       fu.total_sales,
       fu.sales_cnt,
       fu.total_promo_cost
FROM final_union fu
EXCEPT
SELECT fu2.i_item_sk,
       fu2.i_category,
       fu2.i_brand,
       fu2.total_sales,
       fu2.sales_cnt,
       fu2.total_promo_cost
FROM final_union fu2
WHERE fu2.total_sales IS NULL
ORDER BY total_sales DESC
LIMIT 100
