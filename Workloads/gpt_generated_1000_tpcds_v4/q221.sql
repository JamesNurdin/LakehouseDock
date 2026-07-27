WITH agg AS (
    SELECT
        cr_refunded_hdemo_sk,
        cr_returning_hdemo_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_return_quantity) AS sum_qty,
        COUNT(*) AS cnt,
        CASE
            WHEN SUM(cr_return_amount) > 1000 THEN 'HIGH'
            WHEN SUM(cr_return_amount) > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amt_cat
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity >= 1
      AND cr_fee < 20
    GROUP BY cr_refunded_hdemo_sk, cr_returning_hdemo_sk
)
SELECT
    hd_ref.hd_demo_sk AS refunded_demo_sk,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    hd_ret.hd_demo_sk AS returning_demo_sk,
    hd_ret.hd_income_band_sk AS returning_income_band,
    agg.amt_cat,
    agg.sum_return_amount,
    agg.sum_qty,
    agg.cnt,
    agg.sum_return_amount / NULLIF(agg.cnt, 0) AS avg_return_amount
FROM agg
JOIN household_demographics hd_ref
    ON agg.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON agg.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE hd_ref.hd_income_band_sk IN (5, 12, 20)
  AND hd_ret.hd_vehicle_count >= 0
  AND agg.amt_cat <> 'LOW'
ORDER BY agg.sum_return_amount DESC
LIMIT 100
