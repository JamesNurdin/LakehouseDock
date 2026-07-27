WITH promo_agg AS (
    SELECT
        p.p_item_sk,
        COUNT(*) AS promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(CASE WHEN regexp_like(p.p_channel_details, '(?i)radio') THEN 1 ELSE 0 END) AS radio_promo_cnt
    FROM promotion p
    WHERE p.p_channel_press = 'Y' OR p.p_channel_radio = 'Y'
    GROUP BY p.p_item_sk
),
brand_avg AS (
    SELECT
        i.i_brand,
        AVG(p.p_cost) AS avg_brand_promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_brand
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_current_price,
    CASE WHEN i.i_current_price > 100 THEN 'expensive' ELSE 'regular' END AS price_category,
    regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
    COALESCE(pa.promo_cnt, 0) AS promo_count,
    COALESCE(pa.total_promo_cost, 0) AS total_promo_cost,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND regexp_like(p2.p_channel_details, '(?i)event')
        ) THEN 'has_event'
        ELSE 'no_event'
    END AS event_promo_flag,
    ba.avg_brand_promo_cost
FROM item i
LEFT JOIN promo_agg pa ON i.i_item_sk = pa.p_item_sk
LEFT JOIN brand_avg ba ON i.i_brand = ba.i_brand
WHERE i.i_rec_start_date <= DATE '2000-12-31'
  AND i.i_rec_end_date >= DATE '2000-01-01'
  AND i.i_category LIKE '%Electronics%'
ORDER BY total_promo_cost DESC, i.i_item_id
LIMIT 100
