WITH high_returns AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate >= 8000
      AND sr.sr_return_amt_inc_tax > 200
    GROUP BY GROUPING SETS (
        (cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status),
        (cd.cd_gender, cd.cd_marital_status),
        (cd.cd_gender),
        ()
    )
),
low_returns AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate <= 4000
      AND sr.sr_return_amt_inc_tax <= 100
    GROUP BY GROUPING SETS (
        (cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status),
        (cd.cd_gender, cd.cd_marital_status),
        (cd.cd_gender),
        ()
    )
),
-- Subtract low‑return groups from high‑return groups
diff AS (
    SELECT
        hr.cd_demo_sk,
        hr.cd_gender,
        hr.cd_marital_status,
        hr.total_return_inc_tax,
        hr.return_cnt
    FROM high_returns hr
    WHERE hr.total_return_inc_tax IS NOT NULL
    EXCEPT
    SELECT
        lr.cd_demo_sk,
        lr.cd_gender,
        lr.cd_marital_status,
        lr.total_return_inc_tax,
        lr.return_cnt
    FROM low_returns lr
    WHERE lr.total_return_inc_tax IS NOT NULL
)
SELECT DISTINCT
    d.cd_gender,
    d.cd_marital_status,
    d.total_return_inc_tax,
    d.return_cnt,
    (
        SELECT AVG(sr2.sr_net_loss)
        FROM store_returns sr2
        JOIN customer_demographics cd2 ON sr2.sr_cdemo_sk = cd2.cd_demo_sk
        WHERE cd2.cd_gender = d.cd_gender
          AND cd2.cd_marital_status = d.cd_marital_status
          AND sr2.sr_return_amt_inc_tax > d.total_return_inc_tax / 2
    ) AS avg_net_loss
FROM diff d
ORDER BY d.total_return_inc_tax DESC
LIMIT 100
