WITH promo_enhanced AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_cost,
        p.p_purpose,
        p.p_channel_details,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days,
        regexp_extract(p.p_channel_details, '(\\w+)\\s+churches', 1) AS extracted_word,
        CASE
            WHEN regexp_like(p.p_channel_details, '(?i)almost') THEN 'ContainsAlmost'
            ELSE 'Other'
        END AS channel_flag,
        CONCAT(i.i_brand, ' - ', i.i_category) AS brand_category_concat,
        substr(i.i_product_name, 1, 10) AS product_name_prefix
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE d_start.d_year = 2001
      AND i.i_product_name LIKE '%Deluxe%'
      AND regexp_like(p.p_channel_details, '(?i)churches')
)
SELECT
    brand_category_concat,
    extracted_word,
    channel_flag,
    COUNT(DISTINCT p_promo_sk) AS promotion_count,
    AVG(p_cost) AS avg_promo_cost,
    AVG(promo_duration_days) AS avg_duration_days
FROM promo_enhanced
GROUP BY
    brand_category_concat,
    extracted_word,
    channel_flag
ORDER BY promotion_count DESC
LIMIT 100
