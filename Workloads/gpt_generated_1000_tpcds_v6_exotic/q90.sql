WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cp.cp_catalog_page_id,
        cp.cp_description,
        p.p_promo_name,
        cc.cc_name,
        d.d_year,
        regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
        CASE
            WHEN regexp_like(cp.cp_description, '(?i)store') THEN 'ContainsStore'
            ELSE 'Other'
        END AS desc_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%store%'
      AND regexp_like(p.p_promo_name, '^.*Discount.*$')
)
SELECT
    cc_name,
    p_promo_name,
    desc_category,
    first_word,
    COUNT(*) AS orders,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_net_paid) AS total_net_paid,
    ROUND(AVG(cs_ext_sales_price), 2) AS avg_ext_sales_price,
    CONCAT(cc_name, ' - ', p_promo_name) AS combined_label
FROM filtered_sales
GROUP BY
    cc_name,
    p_promo_name,
    desc_category,
    first_word,
    CONCAT(cc_name, ' - ', p_promo_name)
ORDER BY total_net_paid DESC
LIMIT 100
