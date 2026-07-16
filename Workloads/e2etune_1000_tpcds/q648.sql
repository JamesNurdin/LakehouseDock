WITH promo_item_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        COUNT(p.p_promo_sk) AS promo_cnt,
        SUM(p.p_cost) AS total_cost,
        AVG(p.p_cost) AS avg_cost
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_start_date_sk >= 2451545
      AND p.p_discount_active = 'Y'
      AND i.i_current_price > 100
    GROUP BY i.i_category, i.i_brand
    HAVING COUNT(p.p_promo_sk) >= 5
)
SELECT
    i_category,
    i_brand,
    promo_cnt,
    total_cost,
    avg_cost,
    RANK() OVER (ORDER BY total_cost DESC) AS cost_rank
FROM promo_item_agg
ORDER BY total_cost DESC
LIMIT 20
