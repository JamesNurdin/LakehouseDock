WITH enriched AS (
    SELECT
        d_ret.d_year,
        d_ret.d_moy,
        s.s_state,
        ws.web_name,
        r.r_reason_desc,
        cd.cd_education_status,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND t.t_am_pm = 'PM'
),
aggregated AS (
    SELECT
        d_year,
        d_moy,
        s_state,
        web_name,
        r_reason_desc,
        cd_education_status,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr_return_quantity) AS avg_quantity
    FROM enriched
    GROUP BY d_year, d_moy, s_state, web_name, r_reason_desc, cd_education_status
    HAVING SUM(wr_net_loss) > 1000
)
SELECT
    d_year,
    d_moy,
    s_state,
    web_name,
    r_reason_desc,
    cd_education_status,
    total_net_loss,
    return_cnt,
    avg_quantity,
    RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY d_year, d_moy, loss_rank
LIMIT 20
