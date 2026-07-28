WITH return_summary AS (
    SELECT
        sr.sr_customer_sk AS sr_customer_sk,
        cd.cd_gender AS cd_gender,
        hd.hd_income_band_sk AS hd_income_band_sk,
        r.r_reason_desc AS r_reason_desc,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        COUNT(*) AS return_cnt
    FROM tpcds.store_returns AS sr
    JOIN tpcds.customer_demographics AS cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics AS hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.reason AS r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 2
      AND sr.sr_return_tax > 5.0
    GROUP BY sr.sr_customer_sk, cd.cd_gender, hd.hd_income_band_sk, r.r_reason_desc
)
SELECT
    rs.sr_customer_sk,
    rs.cd_gender,
    rs.hd_income_band_sk,
    rs.r_reason_desc,
    rs.total_refunded,
    rs.return_cnt
FROM return_summary AS rs
WHERE rs.r_reason_desc LIKE '%duplicate%'
  AND rs.total_refunded > (
        SELECT AVG(total_refunded) FROM return_summary
    )
UNION ALL
SELECT
    rs.sr_customer_sk,
    rs.cd_gender,
    rs.hd_income_band_sk,
    rs.r_reason_desc,
    rs.total_refunded,
    rs.return_cnt
FROM return_summary AS rs
WHERE rs.r_reason_desc LIKE '%warranty%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns AS sr2
        JOIN tpcds.reason AS r2
            ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_customer_sk = rs.sr_customer_sk
          AND r2.r_reason_desc LIKE '%warranty%'
          AND sr2.sr_reversed_charge > 100
    )
ORDER BY total_refunded DESC, return_cnt ASC
