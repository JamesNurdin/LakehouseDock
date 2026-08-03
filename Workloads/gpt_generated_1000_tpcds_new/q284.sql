WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_brand AS brand,
    i.i_product_name AS product_name,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 5000 THEN 'High'
        ELSE 'Low'
    END AS sales_category,
    REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1) AS product_number,
    CONCAT(p.p_promo_name, ' - ', sm.sm_type) AS promo_detail,
    (
        SELECT COALESCE(SUM(cr.cr_return_quantity), 0)
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
    ) AS total_return_quantity
FROM cs_sample cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE REGEXP_LIKE(i.i_product_name, '(?i)pro|max')
  AND p.p_promo_name LIKE '%discount%'
GROUP BY
    i.i_brand,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    sm.sm_type,
    i.i_item_sk
LIMIT 100
