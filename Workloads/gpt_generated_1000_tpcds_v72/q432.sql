WITH brand_max_price AS (
    SELECT i_brand_id, MAX(i_current_price) AS max_price
    FROM tpcds.item
    GROUP BY i_brand_id
)
SELECT
    i.i_brand,
    i.i_brand_id,
    COUNT(p.p_promo_sk) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(p.p_cost) AS min_promo_cost,
    MAX(p.p_cost) AS max_promo_cost,
    (
        SELECT COUNT(*)
        FROM tpcds.promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    ) AS item_total_promos
FROM tpcds.promotion p
JOIN tpcds.item i
  ON p.p_item_sk = i.i_item_sk
JOIN brand_max_price bmp
  ON i.i_brand_id = bmp.i_brand_id
WHERE i.i_brand_id IN (10008011, 1004002, 3002001)
  AND i.i_class_id = 9
  AND i.i_size = 'extra large'
  AND p.p_channel_dmail = 'Y'
  AND p.p_channel_radio = 'N'
  AND p.p_cost > 0
GROUP BY i.i_brand, i.i_brand_id, bmp.max_price, i.i_item_sk
HAVING SUM(p.p_cost) > bmp.max_price
ORDER BY total_promo_cost DESC
LIMIT 100
