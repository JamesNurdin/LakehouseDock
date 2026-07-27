WITH filtered AS (
    SELECT
        sr.sr_return_amt,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        t.t_meal_time
    FROM store_returns sr
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE hd.hd_income_band_sk IN (6, 14, 20)
      AND hd.hd_buy_potential = '5001-10000'
      AND t.t_meal_time = 'lunch'
      AND (r.r_reason_desc = 'duplicate purchase' OR r.r_reason_desc IS NULL)
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    t_meal_time,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt) AS avg_return_amt,
    MIN(sr_return_amt) AS min_return_amt,
    MAX(sr_return_amt) AS max_return_amt,
    SUM(SUM(sr_return_amt)) OVER (
        PARTITION BY hd_income_band_sk
        ORDER BY hd_buy_potential
        ROWS UNBOUNDED PRECEDING
    ) AS cum_return_by_income
FROM filtered
GROUP BY hd_income_band_sk, hd_buy_potential, t_meal_time
ORDER BY total_return_amt DESC
LIMIT 100
