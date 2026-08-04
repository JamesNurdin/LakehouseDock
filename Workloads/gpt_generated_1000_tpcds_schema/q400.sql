WITH base_sales AS (
    SELECT
        p.p_promo_id,
        p.p_item_sk,
        i.i_brand,
        i.i_category,
        p.p_cost,
        p.p_discount_active
    FROM promotion p
    FULL OUTER JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE (i.i_wholesale_cost IS NOT NULL AND i.i_wholesale_cost > 20)
       OR (p.p_cost IS NOT NULL AND p.p_cost > 800)
),
unioned AS (
    SELECT
        i_brand AS brand,
        i_category AS category,
        p_promo_id AS promo_id,
        CASE WHEN p_discount_active = 'Y' THEN p_cost * 0.9 ELSE p_cost END AS adjusted_cost,
        p_discount_active
    FROM base_sales
    WHERE p_promo_id IS NOT NULL
    UNION ALL
    SELECT
        i_brand AS brand,
        i_category AS category,
        p_promo_id AS promo_id,
        CASE WHEN p_discount_active = 'Y' THEN p_cost * 0.9 ELSE p_cost END AS adjusted_cost,
        p_discount_active
    FROM base_sales
    WHERE i_brand = 'BrandY' AND p_cost > 1500
)
SELECT
    brand,
    category,
    promo_id,
    SUM(adjusted_cost) AS total_adj_cost,
    CASE WHEN COUNT(*) FILTER (WHERE p_discount_active = 'Y') > 0 THEN 'Has Discount' ELSE 'No Discount' END AS discount_flag
FROM unioned
GROUP BY CUBE(brand, category, promo_id)
HAVING SUM(adjusted_cost) IS NOT NULL
EXCEPT
SELECT
    brand,
    category,
    promo_id,
    total_adj_cost,
    discount_flag
FROM (
    SELECT
        i_brand AS brand,
        i_category AS category,
        p_promo_id AS promo_id,
        SUM(CASE WHEN p_discount_active = 'Y' THEN p_cost * 0.9 ELSE p_cost END) AS total_adj_cost,
        CASE WHEN COUNT(*) FILTER (WHERE p_discount_active = 'Y') > 0 THEN 'Has Discount' ELSE 'No Discount' END AS discount_flag
    FROM base_sales
    WHERE i_brand = 'BrandZ'
    GROUP BY CUBE(i_brand, i_category, p_promo_id)
) excl
ORDER BY total_adj_cost DESC
LIMIT 100
