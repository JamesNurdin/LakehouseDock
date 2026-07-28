WITH store_losses AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%Damaged%'
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
),
catalog_losses AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2002
      AND cc.cc_state = 'CA'
      AND r.r_reason_desc LIKE '%Damaged%'
    GROUP BY d.d_year, d.d_month_seq, r.r_reason_desc
)
SELECT *
FROM store_losses
UNION ALL
SELECT *
FROM catalog_losses
ORDER BY year, month_seq, total_net_loss DESC
