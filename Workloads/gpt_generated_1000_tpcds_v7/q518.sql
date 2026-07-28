WITH filtered AS (
    SELECT
        cs.cs_net_paid_inc_tax,
        p.p_promo_name,
        cp.cp_description,
        i.i_product_name
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(cp.cp_description, '(?i)blue')
      AND i.i_product_name LIKE 'A%'
)
SELECT
    CONCAT(p.p_promo_name, '_', REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)) AS promo_desc_key,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    SUBSTRING(i.i_product_name, 1, 5) AS prod_prefix
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE regexp_like(cp.cp_description, '(?i)blue')
  AND i.i_product_name LIKE 'A%'
GROUP BY
    CONCAT(p.p_promo_name, '_', REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1)),
    SUBSTRING(i.i_product_name, 1, 5)
HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
ORDER BY total_net_paid DESC
LIMIT 20
