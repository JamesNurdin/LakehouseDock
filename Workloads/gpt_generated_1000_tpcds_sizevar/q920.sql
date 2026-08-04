WITH
    sampled_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10) /* sample 10% of rows */
        WHERE sr_net_loss > 500
          AND sr_return_quantity >= 1
          AND sr_return_amt_inc_tax > 0
          AND sr_fee < 100
          AND sr_return_ship_cost >= 0
    ),
    agg_returns AS (
        SELECT
            sr_hdemo_sk,
            SUM(sr_net_loss) AS total_net_loss,
            SUM(sr_return_quantity) AS total_return_qty,
            AVG(sr_return_amt) AS avg_return_amt
        FROM sampled_returns
        GROUP BY sr_hdemo_sk
    ),
    full_demo_income AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM household_demographics hd
        FULL OUTER JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_income_band_sk IN (
                SELECT ib_income_band_sk
                FROM income_band
                WHERE ib_lower_bound > 50000
            )
          AND hd.hd_dep_count >= 1
          AND hd.hd_vehicle_count <= 2
          AND ib.ib_upper_bound <= 200000
          AND ib.ib_lower_bound >= 60000
    )
SELECT
    fdi.hd_demo_sk,
    fdi.hd_income_band_sk,
    fdi.hd_buy_potential,
    fdi.hd_dep_count,
    fdi.hd_vehicle_count,
    fdi.ib_lower_bound,
    fdi.ib_upper_bound,
    ar.total_net_loss,
    ar.total_return_qty,
    ar.avg_return_amt
FROM full_demo_income fdi
LEFT JOIN agg_returns ar
    ON fdi.hd_demo_sk = ar.sr_hdemo_sk
WHERE ar.total_net_loss IS NOT NULL
ORDER BY ar.total_net_loss DESC
LIMIT 100
