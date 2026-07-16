WITH aggregated_returns AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_department,
        d_ret.d_year,
        d_ret.d_month_seq,
        r.r_reason_desc,
        ws.web_name,
        ws.web_city,
        ws.web_state,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        date_diff('day', d_start.d_date, d_end.d_date) AS page_duration_days
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_start.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE cp.cp_type = 'quarterly'
      AND d_ret.d_year = 2022
      AND d_end.d_year >= 2022
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_type,
        cp.cp_department,
        d_ret.d_year,
        d_ret.d_month_seq,
        r.r_reason_desc,
        ws.web_name,
        ws.web_city,
        ws.web_state,
        d_start.d_date,
        d_end.d_date
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    ar.cp_catalog_page_id,
    ar.cp_type,
    ar.cp_department,
    ar.d_year,
    ar.d_month_seq,
    ar.r_reason_desc,
    ar.web_name,
    ar.web_city,
    ar.web_state,
    ar.total_net_loss,
    ar.total_return_qty,
    ar.avg_return_amount,
    ar.page_duration_days,
    ROW_NUMBER() OVER (PARTITION BY ar.d_year, ar.d_month_seq ORDER BY ar.total_net_loss DESC) AS loss_rank
FROM aggregated_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 20
