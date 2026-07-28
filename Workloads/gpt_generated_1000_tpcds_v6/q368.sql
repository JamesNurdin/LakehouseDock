WITH promo_data AS (
    SELECT DISTINCT
        i.i_category,
        p.p_promo_name,
        d.d_year,
        'Promotion' AS src
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND p.p_channel_email = 'Y'
),
return_data AS (
    SELECT DISTINCT
        i.i_category,
        CAST(NULL AS varchar) AS p_promo_name,
        d.d_year,
        'Return' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
      AND sr.sr_return_quantity > 0
)
SELECT
    i_category,
    p_promo_name,
    d_year,
    src
FROM promo_data
UNION ALL
SELECT
    i_category,
    p_promo_name,
    d_year,
    src
FROM return_data
ORDER BY i_category, src
