WITH page_info AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        d_start.d_date AS start_date,
        d_end.d_date AS end_date,
        date_diff('day', d_start.d_date, d_end.d_date) AS page_duration_days
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
),
aggregated_returns AS (
    SELECT
        pi.cp_catalog_page_sk,
        pi.cp_catalog_page_id,
        pi.cp_department,
        pi.cp_type,
        pi.start_date,
        pi.end_date,
        pi.page_duration_days,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_store.d_date AS store_closed_date
    FROM page_info pi
    JOIN catalog_returns cr ON cr.cr_catalog_page_sk = pi.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE pi.cp_type = 'Online'
      AND d_ret.d_year BETWEEN 2020 AND 2022
      AND s.s_state = 'CA'
    GROUP BY
        pi.cp_catalog_page_sk,
        pi.cp_catalog_page_id,
        pi.cp_department,
        pi.cp_type,
        pi.start_date,
        pi.end_date,
        pi.page_duration_days,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_store.d_date
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    ar.cp_catalog_page_id,
    ar.cp_department,
    ar.cp_type,
    ar.start_date,
    ar.end_date,
    ar.page_duration_days,
    ar.r_reason_desc,
    ar.total_return_amount,
    ar.avg_net_loss,
    ar.return_count,
    ar.total_return_quantity,
    ar.return_year,
    ar.return_month,
    ar.s_store_id,
    ar.s_store_name,
    ar.s_city,
    ar.s_state,
    ar.store_closed_date,
    RANK() OVER (PARTITION BY ar.cp_department ORDER BY ar.total_return_amount DESC) AS dept_return_rank
FROM aggregated_returns ar
ORDER BY ar.total_return_amount DESC
LIMIT 100
