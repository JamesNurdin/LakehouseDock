WITH filtered_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_item_sk,
       cs.cs_promo_sk,
       cs.cs_ext_sales_price,
       cs.cs_net_paid_inc_tax,
       cp.cp_description,
       i.i_item_desc,
       SUBSTR(i.i_item_desc, 1, 15) AS item_desc_prefix,
       p.p_promo_name,
       d.d_year,
       d.d_month_seq
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE regexp_like(cp.cp_description, '.*[Ee]lectronic.*')
     AND i.i_item_desc LIKE '%Samsung%'
)
SELECT
    d_year,
    d_month_seq,
    p_promo_name,
    item_desc_prefix,
    COUNT(DISTINCT cs_item_sk) AS distinct_items_sold,
    SUM(cs_ext_sales_price) AS total_ext_sales,
    AVG(cs_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    CONCAT('Promo_', REGEXP_EXTRACT(p_promo_name, '(\\w+)', 1)) AS promo_code
FROM filtered_sales
GROUP BY d_year, d_month_seq, p_promo_name, item_desc_prefix
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_ext_sales DESC
LIMIT 100
