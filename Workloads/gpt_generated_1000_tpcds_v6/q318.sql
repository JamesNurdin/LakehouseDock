WITH catalog_data AS (
    SELECT DISTINCT
        'catalog' AS return_type,
        d.d_year,
        concat(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_band_range,
        cr.cr_net_loss AS loss_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_net_loss > 0
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
),
store_data AS (
    SELECT DISTINCT
        'store' AS return_type,
        d.d_year,
        concat(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_band_range,
        sr.sr_net_loss AS loss_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_net_loss > 0
      AND sr.sr_return_quantity > 1
),
combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
)
SELECT
    return_type,
    d_year,
    income_band_range,
    SUM(loss_amount) AS total_loss
FROM combined
GROUP BY GROUPING SETS (
    (return_type, d_year, income_band_range),
    (return_type, d_year),
    (return_type, income_band_range),
    (return_type),
    ()
)
ORDER BY return_type,
         d_year NULLS LAST,
         income_band_range NULLS LAST
LIMIT 100
