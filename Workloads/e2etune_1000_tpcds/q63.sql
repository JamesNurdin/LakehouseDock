WITH site_periods AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        ws.web_city,
        d_open.d_date_sk AS open_date_sk,
        d_close.d_date_sk AS close_date_sk
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
),
ranked_reasons AS (
    SELECT
        sp.web_site_id,
        sp.web_name,
        sp.web_city,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_quantity,
        RANK() OVER (PARTITION BY sp.web_site_id ORDER BY SUM(wr.wr_net_loss) DESC) AS reason_rank
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN site_periods sp ON dr.d_date_sk BETWEEN sp.open_date_sk AND sp.close_date_sk
    WHERE dr.d_holiday = 'Y'
      AND dr.d_fy_year = 2022
    GROUP BY sp.web_site_id, sp.web_name, sp.web_city, r.r_reason_desc
)
SELECT
    web_site_id,
    web_name,
    web_city,
    r_reason_desc,
    total_net_loss,
    total_return_amount,
    return_cnt,
    avg_quantity,
    reason_rank
FROM ranked_reasons
WHERE reason_rank <= 5
ORDER BY web_site_id, reason_rank
