WITH agg_promotions AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(p.p_promo_sk) AS promo_cnt,
        AVG(p.p_cost) AS avg_promo_cost
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_color IN ('turquoise', 'sienna', 'spring')
      AND i.i_category_id IN (5, 1, 9)
      AND p.p_response_target >= 10
      AND p.p_channel_catalog = 'Y'
      AND p.p_discount_active = 'N'
    GROUP BY i.i_item_sk, i.i_brand, i.i_category
),
brand_category_summary AS (
    SELECT
        i_brand,
        i_category,
        SUM(total_promo_cost) AS brand_category_cost,
        SUM(promo_cnt) AS brand_category_promo_cnt,
        AVG(avg_promo_cost) AS brand_category_avg_cost
    FROM agg_promotions
    GROUP BY i_brand, i_category
)
SELECT
    bcs.i_brand,
    bcs.i_category,
    bcs.brand_category_cost,
    bcs.brand_category_promo_cnt,
    bcs.brand_category_avg_cost,
    RANK() OVER (PARTITION BY bcs.i_category ORDER BY bcs.brand_category_cost DESC) AS category_rank
FROM brand_category_summary bcs
WHERE bcs.brand_category_cost > 10000
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.promotion p2
        JOIN tpcds.item i2 ON p2.p_item_sk = i2.i_item_sk
        WHERE i2.i_brand = bcs.i_brand
          AND p2.p_promo_name LIKE '%Clearance%'
    )
ORDER BY bcs.brand_category_cost DESC
