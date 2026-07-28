WITH filtered AS (
    SELECT
        i.i_brand,
        i.i_brand_id,
        regexp_extract(i.i_formulation, '(\\d+)', 1) AS numeric_code,
        p.p_cost,
        p.p_promo_id
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_formulation, '[0-9]+[a-z]+')
      AND i.i_product_name LIKE 'A%'
      AND p.p_channel_tv = 'Y'
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
)
SELECT
    i_brand,
    i_brand_id,
    numeric_code,
    SUM(p_cost) AS total_promo_cost,
    COUNT(DISTINCT p_promo_id) AS promo_count
FROM filtered
GROUP BY i_brand, i_brand_id, numeric_code
ORDER BY total_promo_cost DESC
LIMIT 100
