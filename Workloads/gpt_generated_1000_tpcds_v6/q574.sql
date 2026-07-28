WITH returns_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_income_band_sk,
        COUNT(sr.sr_ticket_number) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        CASE
            WHEN hd.hd_dep_count >= 5 THEN 'Large'
            ELSE 'Small'
        END AS dep_size
    FROM
        household_demographics AS hd
        LEFT OUTER JOIN store_returns AS sr
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        (sr.sr_return_quantity > 20 OR sr.sr_return_quantity IS NULL)
        AND (sr.sr_return_tax BETWEEN 1 AND 30 OR sr.sr_return_tax IS NULL)
        AND (sr.sr_return_ship_cost < 400 OR sr.sr_return_ship_cost IS NULL)
        AND hd.hd_buy_potential IN ('0-500','501-1000','>10000','Unknown','5001-10000')
        AND hd.hd_dep_count BETWEEN 2 AND 7
        AND hd.hd_income_band_sk <> 15
        AND (sr.sr_return_amt > 0 OR sr.sr_return_amt IS NULL)
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_income_band_sk,
        CASE WHEN hd.hd_dep_count >= 5 THEN 'Large' ELSE 'Small' END
),
 demo_counts AS (
    SELECT
        dep_size,
        hd_buy_potential,
        COUNT(DISTINCT hd_demo_sk) AS unique_demo_cnt,
        SUM(total_return_amt) AS sum_return_amt,
        AVG(cnt_returns) AS avg_returns_per_demo
    FROM
        returns_by_demo
    GROUP BY
        dep_size,
        hd_buy_potential
)
SELECT
    dep_size,
    hd_buy_potential,
    unique_demo_cnt,
    sum_return_amt,
    avg_returns_per_demo,
    sum_return_amt / NULLIF(unique_demo_cnt, 0) AS avg_return_amt_per_demo
FROM
    demo_counts
WHERE
    sum_return_amt > 1000
    AND unique_demo_cnt >= 1
    AND avg_returns_per_demo > 0
    AND dep_size IS NOT NULL
    AND hd_buy_potential <> 'Unknown'
    AND sum_return_amt < 50000
ORDER BY
    sum_return_amt DESC
LIMIT 100
