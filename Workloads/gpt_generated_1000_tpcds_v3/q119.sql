WITH sr_agg AS (
    SELECT
        sr_hdemo_sk,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        SUM(sr_reversed_charge) AS total_rev_charge
    FROM store_returns
    WHERE
        sr_return_quantity > 1
        AND sr_return_amt > 5.00
        AND sr_reversed_charge >= 0.10
        AND sr_reason_sk IN (10, 19, 51)
        AND sr_return_time_sk BETWEEN 40000 AND 60000
    GROUP BY sr_hdemo_sk
)
SELECT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    SUM(sr.total_return_qty) AS sum_return_qty,
    SUM(sr.total_return_amt) AS sum_return_amt,
    AVG(sr.avg_return_amt) AS avg_return_amt_over_segments,
    CASE
        WHEN AVG(sr.avg_return_amt) > (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_return_amt > 5.00
              AND sr2.sr_reversed_charge >= 0.10
        ) THEN 'Above Overall Avg'
        ELSE 'Below Overall Avg'
    END AS avg_return_vs_overall,
    ROW_NUMBER() OVER (
        PARTITION BY hd.hd_buy_potential
        ORDER BY SUM(sr.total_return_amt) DESC
    ) AS rn_by_buy_potential
FROM sr_agg sr
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE
    hd.hd_vehicle_count >= 0
    AND hd.hd_dep_count BETWEEN 3 AND 9
    AND hd.hd_buy_potential IS NOT NULL
GROUP BY
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count
HAVING
    SUM(sr.total_return_amt) > 5000
ORDER BY
    sum_return_amt DESC
LIMIT 100
