WITH per_reason_income AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
        (
            SELECT MAX(sr2.sr_returned_date_sk)
            FROM store_returns sr2
            JOIN household_demographics hd2 ON sr2.sr_hdemo_sk = hd2.hd_demo_sk
            WHERE hd2.hd_income_band_sk = ib.ib_income_band_sk
              AND sr2.sr_reason_sk = r.r_reason_sk
        ) AS max_returned_date_sk
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_refunded_cash > 50.00
        AND sr.sr_return_tax BETWEEN 5.00 AND 50.00
        AND hd.hd_vehicle_count >= 0
        AND hd.hd_dep_count <= 7
        AND ib.ib_lower_bound >= 20000
        AND r.r_reason_id LIKE 'AAAAAAAA%'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, r.r_reason_id, r.r_reason_sk
)
SELECT
    pri.ib_income_band_sk,
    pri.ib_lower_bound,
    pri.ib_upper_bound,
    SUM(pri.total_return_amt) AS sum_return_amt,
    AVG(pri.total_net_loss) AS avg_net_loss,
    COUNT(*) AS reason_cnt,
    MAX(pri.max_returned_date_sk) AS latest_return_date_sk
FROM per_reason_income pri
WHERE pri.total_return_amt > 500.00
    AND pri.return_cnt >= 5
GROUP BY pri.ib_income_band_sk, pri.ib_lower_bound, pri.ib_upper_bound
HAVING AVG(pri.avg_refunded_cash) > 100.00
ORDER BY avg_net_loss DESC
LIMIT 50
