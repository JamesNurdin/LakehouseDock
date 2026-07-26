WITH item_month_sales AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       cs.cs_sold_date_sk,
       SUM(cs.cs_net_paid) AS total_net_paid,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_net_profit
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, i.i_product_name, cs.cs_sold_date_sk
)
SELECT
   im.cs_sold_date_sk AS sale_date_key,
   im.i_product_name,
   im.total_net_paid,
   im.total_sales,
   im.total_discount,
   CASE
       WHEN im.total_discount / NULLIF(im.total_sales, 0) > 0.2 THEN 'HIGH_DISCOUNT'
       WHEN im.total_discount / NULLIF(im.total_sales, 0) BETWEEN 0.1 AND 0.2 THEN 'MEDIUM_DISCOUNT'
       ELSE 'LOW_DISCOUNT'
   END AS discount_tier,
   ROW_NUMBER() OVER (PARTITION BY im.cs_sold_date_sk ORDER BY im.total_net_profit DESC) AS profit_rank_in_month
FROM item_month_sales im
WHERE im.total_sales > 0
ORDER BY im.cs_sold_date_sk, profit_rank_in_month
LIMIT 20
