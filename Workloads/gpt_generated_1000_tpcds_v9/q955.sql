WITH filtered AS (
    SELECT
        i.i_manufact AS manufacturer,
        i.i_brand AS brand,
        regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code,
        COUNT(p.p_promo_sk) AS promo_count,
        AVG(p.p_cost) AS avg_promo_cost,
        CONCAT(i.i_brand, '-', CAST(EXTRACT(YEAR FROM i.i_rec_start_date) AS varchar)) AS brand_year,
        SUBSTR(i.i_product_name, 1, 10) AS product_name_prefix
    FROM tpcds.item i
    INNER JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '2022-01-01'
      AND i.i_manufact LIKE 'e%'
      AND regexp_like(i.i_product_name, '(Deluxe|Premium)')
      AND p.p_channel_tv = 'Y'
      AND p.p_response_target > 5
    GROUP BY
        i.i_manufact,
        i.i_brand,
        regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1),
        CONCAT(i.i_brand, '-', CAST(EXTRACT(YEAR FROM i.i_rec_start_date) AS varchar)),
        SUBSTR(i.i_product_name, 1, 10)
    HAVING COUNT(p.p_promo_sk) > 5
)
SELECT
    manufacturer,
    brand,
    product_code,
    promo_count,
    avg_promo_cost,
    brand_year,
    product_name_prefix
FROM filtered
ORDER BY avg_promo_cost DESC
LIMIT 100
