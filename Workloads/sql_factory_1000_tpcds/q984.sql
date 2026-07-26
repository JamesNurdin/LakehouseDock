WITH cat_daily AS (
    SELECT 
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
store_daily AS (
    SELECT 
        sr.sr_returned_date_sk AS date_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
),
combined_daily AS (
    SELECT 
        COALESCE(cd.date_sk, sd.date_sk) AS date_sk,
        COALESCE(cd.catalog_net_loss, 0) AS catalog_net_loss,
        COALESCE(sd.store_net_loss, 0) AS store_net_loss,
        COALESCE(cd.catalog_return_cnt, 0) AS catalog_return_cnt,
        COALESCE(sd.store_return_cnt, 0) AS store_return_cnt,
        (COALESCE(cd.catalog_net_loss, 0) + COALESCE(sd.store_net_loss, 0)) AS total_net_loss
    FROM cat_daily cd
    FULL OUTER JOIN store_daily sd ON cd.date_sk = sd.date_sk
)
SELECT 
    date_sk,
    total_net_loss,
    LAG(total_net_loss, 1) OVER (ORDER BY date_sk) AS prev_day_total_net_loss,
    total_net_loss - LAG(total_net_loss, 1) OVER (ORDER BY date_sk) AS net_loss_change,
    CASE 
        WHEN total_net_loss - LAG(total_net_loss, 1) OVER (ORDER BY date_sk) > 0 THEN 'INCREASE'
        WHEN total_net_loss - LAG(total_net_loss, 1) OVER (ORDER BY date_sk) < 0 THEN 'DECREASE'
        ELSE 'NO_CHANGE'
    END AS net_loss_trend,
    ROUND(AVG(total_net_loss) OVER (ORDER BY date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS moving_7day_avg
FROM combined_daily
ORDER BY date_sk
