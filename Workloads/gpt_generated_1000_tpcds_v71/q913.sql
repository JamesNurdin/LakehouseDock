WITH filtered_items AS (
   SELECT
       i_item_sk,
       i_item_id,
       i_item_desc,
       i_brand,
       i_category,
       regexp_extract(i_item_desc, '(\\d{4})', 1) AS year_code,
       substring(i_item_id, 1, 3) AS brand_prefix
   FROM item
   WHERE regexp_like(i_item_desc, '.*[0-9]{4}.*')
     AND i_item_desc LIKE '%COOL%'
),
agg_sales AS (
   SELECT
       d.d_year,
       p.p_promo_name,
       i.i_brand,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       SUM(cs.cs_net_profit) AS total_profit,
       AVG(cs.cs_quantity) AS avg_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN filtered_items i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
     AND p.p_promo_name LIKE '%Summer%'
     AND i.brand_prefix = 'ABC'
   GROUP BY d.d_year, p.p_promo_name, i.i_brand
)
SELECT
    d_year,
    p_promo_name,
    i_brand,
    distinct_orders,
    total_profit,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_profit DESC
LIMIT 100
