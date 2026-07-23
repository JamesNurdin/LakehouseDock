WITH filtered AS (
    SELECT
        i.i_brand AS brand,
        i.i_manufact AS manufacturer,
        i.i_size AS size,
        i.i_current_price AS current_price,
        p.p_promo_sk AS promo_sk,
        p.p_cost AS promo_cost
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_rec_end_date = DATE '2000-10-26'
      AND i.i_manufact IN ('barantipri', 'ableanti')
      AND i.i_size = 'medium'
      AND i.i_current_price > 50.00
      AND p.p_cost > 500.00
      AND p.p_start_date_sk BETWEEN 2450342 AND 2450675
      AND p.p_purpose = 'Unknown'
)
SELECT
    brand,
    manufacturer,
    size,
    COUNT(DISTINCT promo_sk) AS promo_count,
    SUM(promo_cost) AS total_promo_cost,
    AVG(current_price) AS avg_current_price,
    MIN(promo_cost) AS min_promo_cost,
    MAX(promo_cost) AS max_promo_cost
FROM filtered
GROUP BY brand, manufacturer, size
ORDER BY total_promo_cost DESC
