WITH demo_avg AS (
    SELECT 
        hd.hd_demo_sk,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM household_demographics hd
    JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_demo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    wr.wr_order_number,
    wr.wr_return_amt_inc_tax,
    da.avg_return_amt_inc_tax,
    CASE 
        WHEN wr.wr_return_tax > 50 THEN 'HighTax'
        ELSE 'LowTax'
    END AS tax_category,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY wr.wr_return_amt_inc_tax DESC) AS rn,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_refunded_hdemo_sk = hd.hd_demo_sk
              AND wr2.wr_return_amt_inc_tax > 1000
        ) THEN 1 ELSE 0
    END AS has_high_return
FROM household_demographics hd
JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN demo_avg da
    ON da.hd_demo_sk = hd.hd_demo_sk
WHERE
    wr.wr_return_tax > 0
    AND wr.wr_return_tax < 120
    AND hd.hd_dep_count BETWEEN 1 AND 5
    AND hd.hd_vehicle_count >= 0
    AND hd.hd_buy_potential IN ('0-500', '501-1000', '>10000')
ORDER BY
    hd.hd_buy_potential,
    rn
LIMIT 100
