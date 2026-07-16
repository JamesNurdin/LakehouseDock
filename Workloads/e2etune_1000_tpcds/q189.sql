WITH promo_item_agg AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        p.p_promo_name AS promo_name,
        COUNT(*) AS promo_occurrences,
        SUM(i.i_current_price * (1 - CASE WHEN p.p_discount_active = 'Y' THEN 0.1 ELSE 0 END)) AS total_estimated_revenue,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_response_target) AS avg_response_target
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_start_date_sk BETWEEN 2450800 AND 2451100
      AND p.p_channel_tv = 'Y'
      AND i.i_current_price > 10
    GROUP BY i.i_category, i.i_class, p.p_promo_name
    HAVING COUNT(*) > 5
),
ranked AS (
    SELECT
        category,
        class,
        promo_name,
        promo_occurrences,
        total_estimated_revenue,
        total_promo_cost,
        avg_response_target,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_estimated_revenue DESC) AS rank_in_category,
        SUM(total_estimated_revenue) OVER (PARTITION BY category ORDER BY total_estimated_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM promo_item_agg
)
SELECT
    category,
    class,
    promo_name,
    promo_occurrences,
    total_estimated_revenue,
    total_promo_cost,
    avg_response_target,
    rank_in_category,
    cumulative_revenue
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category
