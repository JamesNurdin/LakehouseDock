/* Goal: Rank reasons for web returns by total net loss per day for the year 2001, focusing on returns with significant tax, low account credit, and reasons mentioning price. */
WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_account_credit,
        wr.wr_net_loss,
        wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_tax > 20
      AND wr.wr_account_credit < 500
      AND wr.wr_return_amt > 0
      AND EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = wr.wr_reason_sk
              AND r.r_reason_desc LIKE '%price%'
        )
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    SUM(fr.wr_return_amt) AS total_return_amt,
    SUM(fr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_date
        ORDER BY SUM(fr.wr_net_loss) DESC
    ) AS rn
FROM filtered_returns fr
JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_weekend = 'N'
  AND d.d_current_day = 'N'
GROUP BY d.d_date, d.d_year, d.d_month_seq, r.r_reason_desc
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC, rn
LIMIT 100
