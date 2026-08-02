WITH RECURSIVE wr_rec (wr_returned_date_sk, wr_return_quantity, wr_return_amt, wr_return_tax, wr_refunded_hdemo_sk, wr_returning_hdemo_sk, wr_reason_sk, lvl) AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_reason_sk,
        0 AS lvl
    FROM web_returns wr
    TABLESAMPLE BERNOULLI (10)
    
    UNION ALL
    
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_reason_sk,
        lvl + 1
    FROM wr_rec wr
    WHERE lvl < 1
)

SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN hd_refunded.hd_vehicle_count > 0 THEN 'VehicleOwner' ELSE 'NoVehicle' END AS vehicle_owner_flag,
    COUNT(*) AS return_cnt,
    SUM(wr_rec.wr_return_amt) AS total_return_amt,
    AVG(wr_rec.wr_return_tax) AS avg_return_tax,
    MIN(wr_rec.wr_return_quantity) AS min_return_qty,
    MAX(wr_rec.wr_return_quantity) AS max_return_qty,
    SUM(CASE WHEN wr_rec.wr_return_tax > 0 THEN wr_rec.wr_return_amt ELSE 0 END) AS total_taxed_return_amt,
    SUM(l_refund.refunded_return_cnt) AS total_refunded_cnt,
    SUM(l_refund.refunded_return_sum) AS total_refunded_sum
FROM wr_rec
JOIN household_demographics hd_refunded
    ON wr_rec.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    AND ib.ib_upper_bound BETWEEN 50000 AND 150000
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS refunded_return_cnt,
        SUM(wr2.wr_return_amt) AS refunded_return_sum
    FROM web_returns wr2
    WHERE wr2.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
) AS l_refund ON TRUE
WHERE
    hd_refunded.hd_vehicle_count >= 2
    AND hd_refunded.hd_vehicle_count <= 5
    AND hd_refunded.hd_dep_count BETWEEN 2 AND 8
    AND wr_rec.wr_return_tax > 10
    AND wr_rec.wr_reason_sk IN (11, 40, 58)
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE WHEN hd_refunded.hd_vehicle_count > 0 THEN 'VehicleOwner' ELSE 'NoVehicle' END
ORDER BY
    total_return_amt DESC
