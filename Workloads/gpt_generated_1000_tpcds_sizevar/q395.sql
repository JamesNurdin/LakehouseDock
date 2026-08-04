WITH promo_agg AS (
    SELECT
        p_item_sk,
        SUM(p_cost) AS total_promo_cost,
        COUNT(*) AS promo_cnt,
        COUNT(DISTINCT p_promo_name) AS distinct_promo_names
    FROM promotion
    WHERE p_channel_radio = 'N'
      AND p_purpose = 'Unknown'
      AND p_discount_active = 'Y'
      AND p_cost > 0
      AND p_end_date_sk > p_start_date_sk
      AND p_channel_email = 'N'
    GROUP BY p_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    i.i_color,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    COUNT(DISTINCT i.i_manufact_id) AS distinct_manufacturers,
    SUM(pa.total_promo_cost) AS sum_promo_cost,
    SUM(pa.promo_cnt) AS total_promotions,
    AVG(i.i_current_price) AS avg_current_price
FROM item i
JOIN promo_agg pa
    ON pa.p_item_sk = i.i_item_sk
WHERE i.i_class IN ('scanners', 'hockey')
  AND i.i_units = 'Each'
  AND i.i_current_price BETWEEN 10 AND 100
  AND i.i_rec_start_date >= DATE '1999-01-01'
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND i.i_color = 'Red'
GROUP BY i.i_category, i.i_brand, i.i_color
ORDER BY sum_promo_cost DESC
LIMIT 100
