WITH sales_union AS (
   SELECT cs_sold_date_sk AS sold_date_sk,
          cs_item_sk AS item_sk,
          cs_promo_sk AS promo_sk,
          cs_ext_sales_price AS ext_sales_price,
          cs_net_profit AS net_profit
   FROM catalog_sales
   UNION ALL
   SELECT ss_sold_date_sk,
          ss_item_sk,
          ss_promo_sk,
          ss_ext_sales_price,
          ss_net_profit
   FROM store_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_promo_sk,
          ws_ext_sales_price,
          ws_net_profit
   FROM web_sales
), aggregated AS (
   SELECT d.d_year,
          i.i_category,
          i.i_brand,
          SUM(su.ext_sales_price) AS total_sales,
          SUM(su.net_profit) AS total_profit,
          approx_distinct(su.item_sk) AS distinct_items_sold,
          COUNT(DISTINCT su.promo_sk) AS promo_count
   FROM sales_union su
   JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
   JOIN item i ON su.item_sk = i.i_item_sk
   LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY d.d_year, i.i_category, i.i_brand
)
SELECT d_year,
       i_category,
       i_brand,
       total_sales,
       total_profit,
       distinct_items_sold,
       promo_count
FROM (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS rn
   FROM aggregated
) t
WHERE rn <= 5
ORDER BY i_category, total_sales DESC
LIMIT 100
