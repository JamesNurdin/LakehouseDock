WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        w.w_warehouse_name,
        w.w_street_name,
        w.w_street_type,
        w.w_street_number,
        p.p_promo_name,
        p.p_channel_details,
        cp.cp_department,
        d.d_month_seq,
        d.d_year,
        regexp_extract(p.p_channel_details, '(\\w+) families', 1) AS family_word,
        concat(w.w_street_name, ' ', w.w_street_type) AS full_street
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2000
      AND regexp_like(p.p_channel_details, '(?i)family')
      AND w.w_street_name LIKE 'Lincoln%'
      AND substring(w.w_street_number, 1, 1) = '6'
)
SELECT
    w_warehouse_name,
    p_promo_name,
    cp_department,
    d_month_seq,
    sum(cs_ext_sales_price) AS total_sales,
    CASE WHEN sum(cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_category,
    count(*) AS order_cnt,
    max(family_word) AS example_family_word,
    max(full_street) AS example_full_street
FROM filtered_sales
GROUP BY GROUPING SETS (
    (w_warehouse_name, p_promo_name, cp_department, d_month_seq),
    (w_warehouse_name, p_promo_name, d_month_seq),
    (w_warehouse_name, d_month_seq),
    (d_month_seq),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
