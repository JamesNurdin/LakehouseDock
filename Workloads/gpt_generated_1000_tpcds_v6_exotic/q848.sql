/*
Goal: Analyze store return loss by reason descriptions that mention price or color versus those that mention fitting, using regex and LIKE filters, string manipulation, a scalar subquery for overall loss comparison, an EXISTS filter, a CTE for each reason group, and combine the two result sets with UNION ALL. The final list is ordered by total loss and limited to the top 100 rows.
*/
WITH filtered_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_net_loss) AS total_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        (SUM(sr.sr_net_loss) / (
            SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2
        )) AS loss_ratio
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price|color')
      AND r.r_reason_desc LIKE '%store%'
      AND EXISTS (
          SELECT 1 FROM store_returns sr3
          WHERE sr3.sr_store_sk = sr.sr_store_sk
            AND sr3.sr_return_quantity > 5
      )
    GROUP BY r.r_reason_desc
),
fit_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_net_loss) AS total_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        (SUM(sr.sr_net_loss) / (
            SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2
        )) AS loss_ratio
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%fit%'
      AND length(r.r_reason_desc) > 10
    GROUP BY r.r_reason_desc
)
SELECT
    CONCAT(r_reason_desc, ' (', CAST(cnt_returns AS varchar), ')') AS reason_summary,
    cnt_returns,
    total_loss,
    avg_return_amt,
    ROUND(loss_ratio, 3) AS loss_ratio
FROM filtered_agg
UNION ALL
SELECT
    CONCAT(r_reason_desc, ' (', CAST(cnt_returns AS varchar), ')') AS reason_summary,
    cnt_returns,
    total_loss,
    avg_return_amt,
    ROUND(loss_ratio, 3) AS loss_ratio
FROM fit_agg
ORDER BY total_loss DESC
LIMIT 100
