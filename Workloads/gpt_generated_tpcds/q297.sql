WITH promo_item AS (
    SELECT
        item.i_brand,
        item.i_category,
        promotion.p_promo_sk,
        promotion.p_cost,
        item.i_current_price
    FROM promotion
    JOIN item ON promotion.p_item_sk = item.i_item_sk
    WHERE promotion.p_discount_active = 'Y'
      AND promotion.p_cost > 0
),
agg AS (
    SELECT
        i_brand,
        i_category,
        COUNT(DISTINCT p_promo_sk) AS promo_count,
        SUM(p_cost) AS total_promo_cost,
        AVG(p_cost / i_current_price) AS avg_discount_ratio
    FROM promo_item
    GROUP BY i_brand, i_category
)
SELECT
    i_brand,
    i_category,
    promo_count,
    total_promo_cost,
    avg_discount_ratio,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_promo_cost DESC) AS category_rank
FROM agg
ORDER BY i_brand, category_rank
LIMIT 100
