WITH catalog_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'catalog' AS source
    FROM tpcds.catalog_returns cr
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451030
      AND ib.ib_upper_bound <= 100000
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
),
store_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'store' AS source
    FROM tpcds.store_returns sr
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451030
      AND ib.ib_upper_bound <= 100000
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    return_cnt,
    source
FROM catalog_agg
UNION ALL
SELECT
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    return_cnt,
    source
FROM store_agg
ORDER BY total_return_amount DESC
LIMIT 100
