WITH base AS (
    SELECT
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_customer_sk,
        sr.sr_ticket_number,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM
        store_returns sr
        FULL OUTER JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        sr.sr_return_quantity > 1
        AND sr.sr_return_amt > 10
        AND sr.sr_reversed_charge < 100
        AND hd.hd_dep_count BETWEEN 2 AND 8
        AND hd.hd_income_band_sk IN (1, 6, 7, 8, 10)
        AND hd.hd_vehicle_count >= 1
),
avg_ret AS (
    SELECT avg(sr_return_amt) AS avg_amt FROM store_returns
),
agg AS (
    SELECT
        hd_income_band_sk,
        hd_buy_potential,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        SUM(sr_return_amt) AS total_return_amt,
        MIN(sr_return_amt) AS min_return_amt,
        MAX(sr_return_amt) AS max_return_amt,
        CASE
            WHEN SUM(sr_return_amt) > (SELECT avg_amt FROM avg_ret) * 1.5 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS return_level
    FROM base
    GROUP BY hd_income_band_sk, hd_buy_potential
    HAVING SUM(sr_return_amt) > (SELECT avg_amt FROM avg_ret) * 1.2
)
SELECT DISTINCT
    hd_income_band_sk,
    hd_buy_potential,
    distinct_customers,
    total_return_amt,
    return_level,
    RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_return_amt DESC) AS income_band_rank
FROM agg
WHERE EXISTS (
    SELECT 1
    FROM base b2
    WHERE b2.hd_income_band_sk = agg.hd_income_band_sk
      AND b2.sr_return_quantity > 5
)
ORDER BY total_return_amt DESC, hd_income_band_sk
LIMIT 100
