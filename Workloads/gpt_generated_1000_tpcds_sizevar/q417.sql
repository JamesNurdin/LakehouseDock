WITH hr_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        CASE WHEN hd.hd_dep_count > 5 THEN 'HighDep' ELSE 'LowDep' END AS dep_category,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns
    FROM tpcds.store_returns AS sr
    JOIN tpcds.household_demographics AS hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band AS ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound BETWEEN 40000 AND 110000
      AND ib.ib_lower_bound >= 40001
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
      AND sr.sr_reason_sk IN (10, 19, 24)
      AND hd.hd_buy_potential <> 'Unknown'
      AND hd.hd_vehicle_count <= 2
      AND sr.sr_return_time_sk BETWEEN 30000 AND 60000
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        CASE WHEN hd.hd_dep_count > 5 THEN 'HighDep' ELSE 'LowDep' END
)
SELECT
    dep_category,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(cnt_returns) AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY dep_category ORDER BY AVG(total_return_amt) DESC) AS rn,
    (SELECT MAX(ib_upper_bound) FROM tpcds.income_band WHERE ib_lower_bound > 50000) AS max_upper_bound_gt_50k
FROM hr_agg
GROUP BY dep_category
HAVING AVG(total_return_amt) > 100
ORDER BY avg_total_return_amt DESC
LIMIT 100
