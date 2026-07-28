WITH filtered_items AS (
    SELECT i_item_sk, i_category, i_product_name, i_item_desc
    FROM item
    WHERE regexp_like(i_product_name, '^A.*')
)
SELECT
    d.d_year,
    i.i_category,
    regexp_extract(i.i_product_name, '^([^ ]+)', 1) AS product_prefix,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CONCAT('Category ', i.i_category) AS category_label
FROM catalog_sales cs
JOIN filtered_items i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year = 2001
  AND (cp.cp_description LIKE '%electronics%'
       OR regexp_like(cp.cp_description, '.*[0-9]{4}.*'))
  AND cc.cc_country = 'United States'
GROUP BY
    d.d_year,
    i.i_category,
    regexp_extract(i.i_product_name, '^([^ ]+)', 1)
HAVING SUM(cs.cs_net_profit) > (
    SELECT AVG(cs2.cs_net_profit) * 0.5
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY total_net_profit DESC, i.i_category
