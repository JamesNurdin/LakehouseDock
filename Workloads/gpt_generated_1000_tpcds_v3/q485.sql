WITH promo_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        i.i_size,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(*) AS promo_count,
        AVG(p.p_cost) AS avg_promo_cost,
        MAX(p.p_cost) AS max_promo_cost
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= DATE '2023-01-01'
      AND i.i_rec_end_date >= DATE '2023-01-01'
      AND i.i_class = 'shirts'
      AND i.i_size = 'large'
      AND p.p_channel_event = 'N'
      AND p.p_discount_active = 'Y'
      AND p.p_cost > 1000
    GROUP BY i.i_category, i.i_class, i.i_size
)
SELECT
    pa.i_category,
    pa.i_class,
    pa.i_size,
    pa.total_promo_cost,
    pa.promo_count,
    pa.avg_promo_cost,
    pa.max_promo_cost,
    (SELECT MAX(p_sub.p_cost) FROM promotion p_sub WHERE p_sub.p_item_sk = i.i_item_sk) AS max_item_promo_cost,
    CASE WHEN EXISTS (
        SELECT 1 FROM promotion p_high
        WHERE p_high.p_item_sk = i.i_item_sk
          AND p_high.p_cost > 5000
    ) THEN 'Y' ELSE 'N' END AS has_very_high_cost_promo
FROM promo_agg pa
JOIN item i
    ON i.i_category = pa.i_category
   AND i.i_class = pa.i_class
   AND i.i_size = pa.i_size
WHERE pa.total_promo_cost > (
    SELECT AVG(p_all.p_cost) FROM promotion p_all
)
ORDER BY pa.total_promo_cost DESC
LIMIT 100
