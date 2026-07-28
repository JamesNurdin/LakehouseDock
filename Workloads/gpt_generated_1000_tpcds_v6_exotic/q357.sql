WITH returns_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        sr.sr_item_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_refunded_cash,
        CASE 
            WHEN sr.sr_return_amt_inc_tax > 1000 THEN 'HIGH'
            WHEN sr.sr_return_amt_inc_tax > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_level
    FROM tpcds.household_demographics AS hd
    LEFT JOIN tpcds.store_returns AS sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count BETWEEN 1 AND 8
      AND hd.hd_income_band_sk IN (2, 3, 8, 15)
      AND hd.hd_vehicle_count >= 1
      AND (sr.sr_refunded_cash IS NULL OR sr.sr_refunded_cash > 20)
      AND (sr.sr_return_amt_inc_tax IS NULL OR sr.sr_return_amt_inc_tax >= 20)
      AND (sr.sr_item_sk IS NULL OR sr.sr_item_sk IN (271991, 263539, 24289))
),
agg AS (
    SELECT
        hd_income_band_sk,
        return_level,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(*) AS transaction_cnt
    FROM returns_by_demo
    GROUP BY GROUPING SETS (
        (hd_income_band_sk, return_level),
        (hd_income_band_sk),
        ()
    )
)
SELECT
    hd_income_band_sk,
    return_level,
    total_refunded_cash,
    total_return_amt_inc_tax,
    transaction_cnt,
    RANK() OVER (ORDER BY total_refunded_cash DESC) AS refunded_cash_rank
FROM agg
ORDER BY refunded_cash_rank
LIMIT 100
