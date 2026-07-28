WITH promo_summary AS (
    SELECT
        p_item_sk,
        SUM(p_cost) AS total_promo_cost,
        COUNT(*) AS promo_count,
        AVG(p_response_target) AS avg_response_target,
        MIN(p_end_date_sk) AS earliest_end_sk
    FROM promotion
    WHERE p_channel_radio = 'N'
      AND p_discount_active = 'Y'
      AND p_purpose LIKE '%Clearance%'
      AND p_end_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY p_item_sk
),
joined AS (
    SELECT
        i.i_category,
        i.i_brand,
        ps.total_promo_cost,
        ps.promo_count,
        ps.avg_response_target,
        ps.earliest_end_sk
    FROM item i
    JOIN promo_summary ps
        ON ps.p_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (41, 34, 25)
      AND i.i_class_id BETWEEN 1 AND 5
      AND i.i_color IS NOT NULL
      AND i.i_size <> ''
)
SELECT
    i_category,
    i_brand,
    SUM(total_promo_cost) AS sum_promo_cost,
    SUM(promo_count) AS total_promos,
    AVG(avg_response_target) AS avg_response_target_over_brands
FROM joined
GROUP BY GROUPING SETS ((i_category, i_brand), (i_category), ())
HAVING SUM(total_promo_cost) > 10000
ORDER BY
    i_category,
    i_brand
LIMIT 100
