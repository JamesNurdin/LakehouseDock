WITH sampled_sales AS (
    SELECT cs_sold_date_sk,
           cs_catalog_page_sk,
           cs_item_sk,
           cs_promo_sk,
           cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT cp.cp_department,
       i.i_brand,
       SUBSTRING(i.i_product_name, 1, 10) AS short_name,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
FROM sampled_sales cs
INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
WHERE REGEXP_LIKE(cp.cp_description, '(?i)guidelines')
  AND p.p_channel_details LIKE '%families%'
  AND i.i_class = 'shirts'
GROUP BY cp.cp_department,
         i.i_brand,
         SUBSTRING(i.i_product_name, 1, 10)
ORDER BY total_profit DESC
