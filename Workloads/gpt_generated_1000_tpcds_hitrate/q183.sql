WITH sales_item AS (
   SELECT cs.cs_promo_sk,
          cs.cs_item_sk,
          cs.cs_net_paid,
          cs.cs_quantity
   FROM catalog_sales cs
), joined AS (
   SELECT p.p_promo_id,
          p.p_promo_name,
          regexp_extract(p.p_promo_id, '(\\d+)', 1) AS promo_num,
          i.i_category,
          i.i_product_name,
          cs.cs_net_paid,
          cs.cs_quantity
   FROM sales_item cs
   RIGHT OUTER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE p.p_promo_name LIKE '%sale%'
     AND (i.i_product_name IS NULL OR regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}'))
)
SELECT p_promo_id,
       p_promo_name,
       promo_num,
       i_category,
       COUNT(cs_net_paid) AS sales_cnt,
       SUM(cs_net_paid) AS total_net_paid,
       SUM(cs_quantity) AS total_quantity
FROM joined
GROUP BY p_promo_id, p_promo_name, promo_num, i_category
ORDER BY total_net_paid DESC
LIMIT 100
