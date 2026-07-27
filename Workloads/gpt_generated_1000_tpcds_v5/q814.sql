/*
Goal: Compare total return amounts from catalog and web channels for high‑income households, broken down by shipping carrier for catalog returns.
*/
WITH catalog_agg AS (
    SELECT
        'catalog' AS return_source,
        sm.sm_carrier AS carrier,
        ib.ib_upper_bound AS income_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sm.sm_carrier IN ('FEDEX', 'TBS')
      AND ib.ib_upper_bound > 90000
    GROUP BY sm.sm_carrier, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        'web' AS return_source,
        CAST(NULL AS varchar) AS carrier,
        ib.ib_upper_bound AS income_upper_bound,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 90000
    GROUP BY ib.ib_upper_bound
)
SELECT return_source,
       carrier,
       income_upper_bound,
       total_return_amount
FROM catalog_agg
UNION ALL
SELECT return_source,
       carrier,
       income_upper_bound,
       total_return_amount
FROM web_agg
ORDER BY return_source,
         total_return_amount DESC
LIMIT 100
