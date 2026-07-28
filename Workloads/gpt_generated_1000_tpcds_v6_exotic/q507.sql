WITH promo_returns AS (
    SELECT DISTINCT
        i.i_item_id AS item_id,
        cr.cr_return_amount AS return_amount,
        p.p_promo_name AS promo_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_purpose = 'Unknown'
      AND ib.ib_upper_bound <= 100000
      AND NOT EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_promo_name <> p.p_promo_name
        )
),
no_promo_returns AS (
    SELECT
        i.i_item_id AS item_id,
        cr.cr_return_amount AS return_amount,
        CAST(NULL AS varchar) AS promo_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM promotion p3
            WHERE p3.p_item_sk = i.i_item_sk
        )
      AND ib.ib_upper_bound <= 100000
)
SELECT
    item_id,
    return_amount,
    promo_name
FROM (
    SELECT * FROM promo_returns
    UNION ALL
    SELECT * FROM no_promo_returns
) combined
ORDER BY return_amount DESC, item_id
LIMIT 100
