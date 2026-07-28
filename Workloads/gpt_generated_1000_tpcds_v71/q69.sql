WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        dm.cd_gender,
        dm.cd_marital_status,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        d.d_year,
        d.d_date_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics dm
        ON cr.cr_refunded_cdemo_sk = dm.cd_demo_sk
    JOIN household_demographics hh
        ON cr.cr_refunded_hdemo_sk = hh.hd_demo_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'UPS'
      AND dm.cd_marital_status = 'M'
      AND hh.hd_income_band_sk BETWEEN 3 AND 5
)
SELECT
    fr.d_year,
    fr.sm_ship_mode_id,
    CASE
        WHEN fr.cd_gender = 'M' THEN 'Male'
        WHEN fr.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_category,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_creation_date_sk = fr.cr_returned_date_sk
      AND wp.wp_type = 'product'
)
GROUP BY
    fr.d_year,
    fr.sm_ship_mode_id,
    CASE
        WHEN fr.cd_gender = 'M' THEN 'Male'
        WHEN fr.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END
ORDER BY total_return_amount DESC
LIMIT 100
