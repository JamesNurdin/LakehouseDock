WITH store_agg AS (
    SELECT r.r_reason_desc AS reason,
           td.t_hour AS hour,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND c.c_birth_country = 'JAPAN'
    GROUP BY r.r_reason_desc, td.t_hour
),
web_agg AS (
    SELECT r.r_reason_desc AS reason,
           td.t_hour AS hour,
           SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND c.c_birth_country = 'MONACO'
    GROUP BY r.r_reason_desc, td.t_hour
)
SELECT reason, hour, total_net_loss
FROM store_agg
UNION ALL
SELECT reason, hour, total_net_loss
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
