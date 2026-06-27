WITH sales_by_hour AS (
    SELECT
        sold_time.t_hour AS hour,
        sum(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN time_dim sold_time
        ON ss.ss_sold_time_sk = sold_time.t_time_sk
    GROUP BY sold_time.t_hour
),
returns_by_hour_reason AS (
    SELECT
        return_time.t_hour AS hour,
        r.r_reason_desc AS reason_desc,
        sum(sr.sr_net_loss) AS total_returns
    FROM store_returns sr
    JOIN time_dim return_time
        ON sr.sr_return_time_sk = return_time.t_time_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY return_time.t_hour, r.r_reason_desc
)
SELECT
    r.hour,
    r.reason_desc,
    coalesce(s.total_sales, 0) AS total_sales,
    r.total_returns,
    coalesce(s.total_sales, 0) - r.total_returns AS net_revenue
FROM returns_by_hour_reason r
LEFT JOIN sales_by_hour s
    ON r.hour = s.hour
ORDER BY r.hour, r.reason_desc
