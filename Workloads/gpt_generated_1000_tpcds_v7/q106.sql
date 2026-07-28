/*
  goal: Compare total net loss by return reason across catalog and store returns for the years 1998‑1999, showing the source (catalog or store) for each reason.
*/
WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        SUM(cr.cr_net_loss) AS total_net_loss,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1999-12-31'
    GROUP BY r.r_reason_desc
),
store_agg AS (
    SELECT
        r.r_reason_desc AS reason,
        SUM(sr.sr_net_loss) AS total_net_loss,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1999-12-31'
      AND sr.sr_refunded_cash > 100
    GROUP BY r.r_reason_desc
)
SELECT reason,
       total_net_loss,
       source
FROM catalog_agg
UNION ALL
SELECT reason,
       total_net_loss,
       source
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 100
