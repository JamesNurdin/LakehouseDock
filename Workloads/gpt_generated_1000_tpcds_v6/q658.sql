WITH closed_current AS (
    SELECT s.s_store_sk,
           s.s_state
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
)
SELECT
    COALESCE(c.s_state, s.s_state) AS state,
    'CurrentYear' AS period,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Profit' ELSE 'Loss' END AS loss_indicator
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN closed_current c ON s.s_store_sk = c.s_store_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE d.d_current_year = 'Y'
  AND hd.hd_vehicle_count >= 1
GROUP BY COALESCE(c.s_state, s.s_state), 'CurrentYear'

UNION ALL

SELECT
    COALESCE(c.s_state, s.s_state) AS state,
    'PreviousYear' AS period,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Profit' ELSE 'Loss' END AS loss_indicator
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN closed_current c ON s.s_store_sk = c.s_store_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE d.d_current_year = 'N'
  AND hd.hd_vehicle_count >= 1
GROUP BY COALESCE(c.s_state, s.s_state), 'PreviousYear'

ORDER BY state, period
