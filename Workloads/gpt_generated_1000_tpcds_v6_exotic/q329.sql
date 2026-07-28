WITH sales_page AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_year,
        cs.cs_promo_sk,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
        CASE WHEN regexp_like(cp.cp_description, '.*(sale|discount).*') THEN 1 ELSE 0 END AS has_keyword
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%catalog%'
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY cp.cp_catalog_page_id,
             d.d_year,
             cs.cs_promo_sk,
             p.p_promo_name,
             regexp_extract(cp.cp_description, '(\\w+)', 1),
             CASE WHEN regexp_like(cp.cp_description, '.*(sale|discount).*') THEN 1 ELSE 0 END
)
SELECT
    sp.cp_catalog_page_id,
    sp.d_year,
    sp.p_promo_name,
    sp.total_sales,
    sp.order_cnt,
    sp.first_word,
    sp.has_keyword
FROM sales_page sp
WHERE sp.total_sales > 1000
  AND sp.has_keyword = 1
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = sp.cs_promo_sk
          AND p2.p_discount_active = 'Y'
      )
ORDER BY sp.total_sales DESC
LIMIT 100
