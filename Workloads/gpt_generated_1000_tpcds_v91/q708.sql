WITH store_ret AS (
    SELECT DISTINCT
        d.d_date,
        r.r_reason_desc,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
),
web_ret AS (
    SELECT DISTINCT
        d.d_date,
        r.r_reason_desc,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_desc LIKE '%color%'
            AND r2.r_reason_sk = wr.wr_reason_sk
      )
),
combined_raw AS (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM web_ret
),
aggregated AS (
    SELECT
        d_date,
        r_reason_desc,
        channel,
        SUM(net_loss) AS total_net_loss
    FROM combined_raw
    GROUP BY d_date, r_reason_desc, channel
    HAVING SUM(net_loss) > 0
)
SELECT
    a.d_date,
    a.r_reason_desc,
    a.channel,
    a.total_net_loss,
    SUM(a.total_net_loss) OVER (
        PARTITION BY a.channel
        ORDER BY a.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_loss,
    (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
FROM aggregated a
ORDER BY a.d_date DESC, a.total_net_loss DESC
LIMIT 100
