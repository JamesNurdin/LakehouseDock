WITH returns_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM
        tpcds.store_returns AS sr
        JOIN tpcds.household_demographics AS hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        sr.sr_return_amt > 30
        AND sr.sr_return_quantity <= 4
        AND sr.sr_reversed_charge BETWEEN 0.20 AND 20.00
        AND hd.hd_vehicle_count IN (0, 1, 3)
        AND hd.hd_dep_count >= 2
    GROUP BY
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count
)
SELECT
    hd_demo_sk,
    hd_vehicle_count,
    hd_dep_count,
    total_return_amt,
    avg_return_tax,
    return_cnt,
    RANK() OVER (PARTITION BY hd_vehicle_count ORDER BY total_return_amt DESC) AS vehicle_return_rank,
    CASE
        WHEN total_return_amt > 200 THEN 'HIGH'
        WHEN total_return_amt BETWEEN 100 AND 200 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level
FROM returns_agg
ORDER BY hd_vehicle_count, vehicle_return_rank
