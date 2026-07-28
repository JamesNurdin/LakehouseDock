WITH filtered_promos AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_name,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1) AS discount_pct,
        CONCAT(p.p_promo_name, ' Discount ', REGEXP_EXTRACT(p.p_promo_name, '(\\d+)%', 1), '%') AS promo_label
    FROM promotion p
    WHERE REGEXP_LIKE(p.p_promo_name, '\\d+%')
),
promo_sales AS (
    SELECT
        fp.promo_label,
        fp.discount_pct,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_cnt
    FROM catalog_sales cs
    JOIN filtered_promos fp ON cs.cs_promo_sk = fp.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state LIKE 'C%'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY fp.promo_label, fp.discount_pct, d.d_year
)
SELECT
    promo_label,
    discount_pct,
    d_year,
    total_sales,
    order_cnt,
    distinct_items_cnt
FROM promo_sales
ORDER BY total_sales DESC
LIMIT 100
