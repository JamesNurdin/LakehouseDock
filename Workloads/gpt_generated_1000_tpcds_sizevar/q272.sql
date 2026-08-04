WITH right_joined AS (
    SELECT
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_promo_sk AS ss_promo_sk,
        p.p_promo_sk AS p_promo_sk,
        p.p_promo_id,
        p.p_purpose,
        p.p_end_date_sk,
        p.p_channel_email
    FROM store_sales ss
    RIGHT OUTER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
)

SELECT promo_key
FROM (
    SELECT p_promo_sk AS promo_key
    FROM right_joined
    WHERE ss_quantity > (SELECT AVG(ss_quantity) FROM store_sales)
    INTERSECT
    SELECT p_promo_sk
    FROM right_joined
    WHERE p_end_date_sk > 2450400
      AND p_promo_sk NOT IN (SELECT ss_promo_sk FROM store_sales WHERE ss_sales_price > 100)
) AS intersected
UNION ALL
SELECT p_promo_sk
FROM right_joined
WHERE p_channel_email = 'Y'
LIMIT 100
