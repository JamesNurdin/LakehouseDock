WITH unioned AS (
    SELECT
        S1.s_store_name AS store_name,
        R1.r_reason_desc AS reason_desc,
        SR.sr_net_loss,
        S1.s_store_sk AS store_sk
    FROM tpcds.store_returns AS SR
    INNER JOIN tpcds.household_demographics AS hd1 ON SR.sr_hdemo_sk = hd1.hd_demo_sk
    INNER JOIN tpcds.income_band AS ib1 ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
    INNER JOIN tpcds.store AS S1 ON SR.sr_store_sk = S1.s_store_sk
    -- extra join to reuse the store table under a different alias
    INNER JOIN tpcds.store AS S3 ON SR.sr_store_sk = S3.s_store_sk
    INNER JOIN tpcds.reason AS R1 ON SR.sr_reason_sk = R1.r_reason_sk
    WHERE SR.sr_reason_sk IN (
        SELECT r_reason_sk FROM tpcds.reason WHERE r_reason_desc LIKE '%price%'
    )
      AND hd1.hd_vehicle_count >= 0

    UNION

    SELECT
        S2.s_store_name AS store_name,
        R2.r_reason_desc AS reason_desc,
        SR.sr_net_loss,
        S2.s_store_sk AS store_sk
    FROM tpcds.store_returns AS SR
    INNER JOIN tpcds.household_demographics AS hd2 ON SR.sr_hdemo_sk = hd2.hd_demo_sk
    INNER JOIN tpcds.income_band AS ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    INNER JOIN tpcds.store AS S2 ON SR.sr_store_sk = S2.s_store_sk
    INNER JOIN tpcds.reason AS R2 ON SR.sr_reason_sk = R2.r_reason_sk
    WHERE SR.sr_reason_sk IN (
        SELECT r_reason_sk FROM tpcds.reason WHERE r_reason_desc LIKE '%Gift%'
    )
      AND hd2.hd_dep_count BETWEEN 2 AND 9
)
SELECT
    store_name,
    reason_desc,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    (
        SELECT SUM(sr3.sr_return_amt)
        FROM tpcds.store_returns AS sr3
        INNER JOIN tpcds.store AS s3 ON sr3.sr_store_sk = s3.s_store_sk
        WHERE s3.s_store_name = unioned.store_name
    ) AS total_store_return_amount
FROM unioned
GROUP BY ROLLUP (store_name, reason_desc)
HAVING SUM(sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
