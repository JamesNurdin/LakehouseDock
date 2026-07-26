WITH daily_loss AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_returned_date_sk AS returned_date_sk,
        SUM(sr.sr_net_loss) AS daily_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_reason_sk, sr.sr_returned_date_sk
)
SELECT
    r.r_reason_desc,
    dl.returned_date_sk,
    dl.daily_net_loss,
    SUM(dl.daily_net_loss) OVER (PARTITION BY dl.sr_reason_sk ORDER BY dl.returned_date_sk) AS cumulative_net_loss,
    LAG(dl.daily_net_loss) OVER (PARTITION BY dl.sr_reason_sk ORDER BY dl.returned_date_sk) AS prev_day_net_loss,
    dl.daily_net_loss - LAG(dl.daily_net_loss) OVER (PARTITION BY dl.sr_reason_sk ORDER BY dl.returned_date_sk) AS net_loss_change,
    CASE
        WHEN dl.daily_net_loss - LAG(dl.daily_net_loss) OVER (PARTITION BY dl.sr_reason_sk ORDER BY dl.returned_date_sk) > 0 THEN 'Increase'
        WHEN dl.daily_net_loss - LAG(dl.daily_net_loss) OVER (PARTITION BY dl.sr_reason_sk ORDER BY dl.returned_date_sk) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS change_category
FROM daily_loss dl
JOIN reason r ON dl.sr_reason_sk = r.r_reason_sk
ORDER BY r.r_reason_desc, dl.returned_date_sk
