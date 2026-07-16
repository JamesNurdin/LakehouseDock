WITH item_margins AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_brand_id,
        i.i_current_price,
        i.i_wholesale_cost,
        (i.i_current_price - i.i_wholesale_cost) AS margin,
        CASE
            WHEN (i.i_current_price - i.i_wholesale_cost) >= 50 THEN 'High'
            WHEN (i.i_current_price - i.i_wholesale_cost) BETWEEN 20 AND 49.99 THEN 'Medium'
            ELSE 'Low'
        END AS margin_category
    FROM item i
    WHERE i.i_current_price IS NOT NULL
      AND i.i_wholesale_cost IS NOT NULL
)
SELECT
    i_item_id,
    i_brand,
    i_brand_id,
    margin,
    margin_category,
    RANK() OVER (PARTITION BY i_brand ORDER BY margin DESC) AS brand_margin_rank,
    DENSE_RANK() OVER (PARTITION BY i_brand ORDER BY margin_category) AS margin_category_rank
FROM item_margins
WHERE margin_category IN ('High', 'Medium')
ORDER BY i_brand, brand_margin_rank
