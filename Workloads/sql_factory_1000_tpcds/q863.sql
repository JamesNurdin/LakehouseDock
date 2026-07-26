SELECT
    category,
    total_sales,
    total_cost,
    total_discount,
    total_promo_cost,
    roi,
    DENSE_RANK() OVER (ORDER BY roi DESC) AS category_roi_rank,
    CASE
        WHEN total_sales > 1000000 THEN 'High'
        WHEN total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category
FROM (
    SELECT
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_wholesale_cost) AS total_cost,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        (SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_wholesale_cost) - COALESCE(SUM(p.p_cost), 0)) / NULLIF(COALESCE(SUM(p.p_cost), 0), 0) AS roi
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY i.i_category
) t
WHERE total_sales > 0
ORDER BY roi DESC
LIMIT 10
