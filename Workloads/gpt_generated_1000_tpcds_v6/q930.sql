WITH agg AS (
    SELECT
        s.s_division_name,
        r.r_reason_desc,
        td.t_hour,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE s.s_zip IN ('29584', '32477')
      AND s.s_geography_class = 'Unknown'
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_division_name, r.r_reason_desc, td.t_hour
    HAVING SUM(sr.sr_net_loss) > 1000
       AND COUNT(*) >= 5
)
SELECT
    s_division_name,
    r_reason_desc,
    t_hour,
    total_net_loss,
    returns_cnt,
    RANK() OVER (PARTITION BY s_division_name ORDER BY total_net_loss DESC) AS reason_rank
FROM agg
ORDER BY s_division_name, reason_rank, t_hour
