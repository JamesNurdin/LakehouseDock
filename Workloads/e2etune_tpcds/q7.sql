WITH store_sales_hourly AS (
    SELECT t.t_hour AS hour_of_day,
           SUM(ss.ss_net_profit) AS store_net_profit,
           COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour
),
web_sales_hourly AS (
    SELECT t.t_hour AS hour_of_day,
           SUM(ws.ws_net_profit) AS web_net_profit,
           COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour
),
returns_hourly_division AS (
    SELECT t.t_hour AS hour_of_day,
           cc.cc_division,
           r.r_reason_desc,
           SUM(cr.cr_net_loss) AS total_return_loss,
           COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND cc.cc_manager = 'Bob Belcher'
    GROUP BY t.t_hour, cc.cc_division, r.r_reason_desc
)
SELECT
    rs.hour_of_day,
    rs.cc_division,
    rs.r_reason_desc,
    ss.store_net_profit,
    ws.web_net_profit,
    rs.total_return_loss,
    rs.returns_cnt
FROM returns_hourly_division rs
LEFT JOIN store_sales_hourly ss ON rs.hour_of_day = ss.hour_of_day
LEFT JOIN web_sales_hourly ws ON rs.hour_of_day = ws.hour_of_day
ORDER BY rs.hour_of_day, rs.cc_division, rs.r_reason_desc
