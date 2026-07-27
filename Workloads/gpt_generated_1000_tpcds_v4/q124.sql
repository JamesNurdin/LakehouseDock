WITH agg_returns AS (
    SELECT
        hd_ref.hd_income_band_sk AS income_band,
        hd_ref.hd_vehicle_count AS vehicle_count,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE
        wr.wr_return_quantity > 0
        AND wr.wr_return_amt > 0
        AND wr.wr_account_credit >= 10
        AND hd_ref.hd_vehicle_count >= 0
        AND hd_ref.hd_dep_count <= 5
    GROUP BY
        hd_ref.hd_income_band_sk,
        hd_ref.hd_vehicle_count
)
SELECT
    income_band,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(returns_cnt) AS sum_returns_cnt,
    MAX(total_net_loss) AS max_total_net_loss
FROM agg_returns
GROUP BY income_band
HAVING AVG(total_return_amt) > 1000
ORDER BY max_total_net_loss DESC
LIMIT 100
