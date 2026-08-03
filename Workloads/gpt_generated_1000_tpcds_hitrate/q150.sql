WITH aggregated_returns AS (
    SELECT
        sr_cdemo_sk,
        sr_hdemo_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(sr_fee) AS avg_fee
    FROM tpcds.store_returns
    WHERE sr_fee > 10
      AND sr_return_tax > 0
      AND sr_reversed_charge < 1000
    GROUP BY sr_cdemo_sk, sr_hdemo_sk
)
SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_dep_college_count,
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ar.total_net_loss,
    ar.return_cnt,
    ar.avg_fee,
    ROW_NUMBER() OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY ar.total_net_loss DESC
    ) AS rank_in_band
FROM aggregated_returns ar
JOIN tpcds.customer_demographics cd
    ON ar.sr_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON ar.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cd.cd_marital_status = 'M'
  AND cd.cd_dep_college_count >= 1
  AND ib.ib_upper_bound <= 150000
ORDER BY ib.ib_income_band_sk, rank_in_band
LIMIT 100
