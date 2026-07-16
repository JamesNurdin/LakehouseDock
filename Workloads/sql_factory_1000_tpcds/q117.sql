WITH daily_category_loss AS (
    SELECT
        sr.sr_returned_date_sk AS return_date,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_returned_date_sk, i.i_category
)
SELECT
    return_date,
    i_category,
    total_net_loss,
    LAG(total_net_loss) OVER (PARTITION BY i_category ORDER BY return_date) AS prev_day_net_loss,
    total_net_loss - LAG(total_net_loss) OVER (PARTITION BY i_category ORDER BY return_date) AS net_loss_change,
    AVG(total_net_loss) OVER (
        PARTITION BY i_category
        ORDER BY return_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7d
FROM daily_category_loss
ORDER BY i_category, return_date
