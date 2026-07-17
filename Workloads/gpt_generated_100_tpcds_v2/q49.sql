WITH hourly_net_loss AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_sk,
        td.t_hour AS hour_of_day,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
    GROUP BY sr.sr_returned_date_sk, td.t_hour
)
SELECT
    hnl.hour_of_day,
    AVG(hnl.total_net_loss) AS avg_daily_net_loss,
    COUNT(*) AS days_with_data
FROM hourly_net_loss hnl
GROUP BY hnl.hour_of_day
HAVING AVG(hnl.total_net_loss) > (
    SELECT AVG(total_net_loss)
    FROM hourly_net_loss
)
ORDER BY avg_daily_net_loss DESC
