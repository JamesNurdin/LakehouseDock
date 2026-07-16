WITH daily_reason_store AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        r.r_reason_desc,
        s.s_division_name,
        t.t_hour,
        COUNT(*) AS returns_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_return_amount) - SUM(cr.cr_net_loss) AS net_gain
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_date, d.d_year, d.d_month_seq, r.r_reason_desc, s.s_division_name, t.t_hour
)

SELECT
    drs.d_date,
    drs.d_year,
    drs.d_month_seq,
    drs.r_reason_desc,
    drs.s_division_name,
    drs.t_hour,
    drs.returns_cnt,
    drs.total_net_loss,
    drs.total_return_amount,
    drs.avg_return_qty,
    drs.net_gain,
    ROUND(drs.total_return_amount / NULLIF(drs.total_net_loss, 0), 2) AS return_to_loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY drs.d_date ORDER BY drs.total_net_loss DESC) AS net_loss_rank,
    RANK() OVER (PARTITION BY drs.r_reason_desc ORDER BY drs.total_return_amount DESC) AS return_amount_reason_rank
FROM daily_reason_store drs
ORDER BY drs.d_date DESC, drs.total_net_loss DESC
LIMIT 150
