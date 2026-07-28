WITH promo_item AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        p.p_channel_email,
        p.p_channel_tv,
        i.i_brand,
        i.i_brand_id,
        i.i_class,
        i.i_color,
        i.i_units
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
)
SELECT
    brand,
    class,
    unit_type,
    SUM(total_cost) AS total_promo_cost,
    COUNT(*) AS promo_cnt
FROM (
    SELECT
        i_brand AS brand,
        i_class AS class,
        CASE WHEN i_units = 'Lb' THEN 'Weight' ELSE 'Other' END AS unit_type,
        p_cost AS total_cost
    FROM promo_item
    WHERE p_channel_email = 'Y'
      AND i_class = 'infants'

    UNION ALL

    SELECT
        i_brand AS brand,
        i_class AS class,
        CASE WHEN i_units = 'Lb' THEN 'Weight' ELSE 'Other' END AS unit_type,
        p_cost AS total_cost
    FROM promo_item
    WHERE p_channel_tv = 'Y'
      AND i_color = 'pink'
) AS combined
GROUP BY brand, class, unit_type
ORDER BY total_promo_cost DESC, brand
