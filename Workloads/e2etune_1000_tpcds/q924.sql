WITH store_agg AS (
    SELECT
        t.t_hour AS hour_of_day,
        hd.hd_vehicle_count AS vehicle_count,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt) AS store_return_amt,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, hd.hd_vehicle_count
),
web_agg AS (
    SELECT
        t.t_hour AS hour_of_day,
        hd.hd_vehicle_count AS vehicle_count,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, hd.hd_vehicle_count
)
SELECT
    COALESCE(s.hour_of_day, w.hour_of_day) AS hour_of_day,
    COALESCE(s.vehicle_count, w.vehicle_count) AS vehicle_count,
    COALESCE(s.store_net_loss, 0) AS store_net_loss,
    COALESCE(w.web_net_loss, 0) AS web_net_loss,
    (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_net_loss,
    (COALESCE(s.store_return_amt, 0) + COALESCE(w.web_return_amt, 0)) AS total_return_amt,
    (COALESCE(s.store_return_cnt, 0) + COALESCE(w.web_return_cnt, 0)) AS total_return_cnt,
    RANK() OVER (ORDER BY (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) DESC) AS loss_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.hour_of_day = w.hour_of_day
    AND s.vehicle_count = w.vehicle_count
WHERE (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 20
