WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_store_credit) AS avg_store_credit,
        COUNT(*) AS cnt_returns,
        MAX(sr.sr_net_loss) AS max_net_loss,
        MIN(sr.sr_net_loss) AS min_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 500 THEN 'HIGH_LOSS'
            ELSE 'LOW_LOSS'
        END AS loss_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_qoy = 2
      AND d.d_following_holiday = 'N'
      AND sr.sr_store_credit > 100
      AND sr.sr_net_loss < 500
    GROUP BY sr.sr_returned_date_sk
),
high_loss_dates AS (
    SELECT sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_net_loss > 400
),
low_loss_dates AS (
    SELECT sr.sr_returned_date_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_net_loss < 200
),
dates_excluding AS (
    SELECT sr_returned_date_sk FROM high_loss_dates
    EXCEPT
    SELECT sr_returned_date_sk FROM low_loss_dates
),
date_with_tax AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        t.total_tax
    FROM date_dim d
    LEFT JOIN LATERAL (
        SELECT SUM(sr.sr_return_tax) AS total_tax
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = d.d_date_sk
    ) t ON TRUE
    WHERE d.d_year = 2002
)
SELECT
    dwt.d_date,
    dwt.d_year,
    dwt.d_quarter_name,
    fr.total_return_amt,
    fr.avg_store_credit,
    fr.cnt_returns,
    fr.loss_category,
    dwt.total_tax,
    (SELECT AVG(sr_store_credit) FROM store_returns) AS overall_avg_store_credit
FROM date_with_tax dwt
FULL OUTER JOIN filtered_returns fr
    ON dwt.d_date_sk = fr.sr_returned_date_sk
WHERE dwt.d_date_sk IN (SELECT sr_returned_date_sk FROM dates_excluding)
ORDER BY dwt.d_date DESC
OFFSET 0
LIMIT 100
