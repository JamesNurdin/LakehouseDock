WITH combined_returns AS (
    SELECT
        'store' AS source,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour >= 12
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_promo_sk IS NOT NULL
      )
    GROUP BY r.r_reason_desc

    UNION ALL

    SELECT
        'web' AS source,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour >= 12
    GROUP BY r.r_reason_desc
)
SELECT
    source,
    reason_desc,
    total_net_loss,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_net_loss DESC) AS rn,
    SUM(total_net_loss) OVER (PARTITION BY source ORDER BY total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM combined_returns
WHERE total_net_loss > (SELECT AVG(total_net_loss) FROM combined_returns)
ORDER BY source, rn
