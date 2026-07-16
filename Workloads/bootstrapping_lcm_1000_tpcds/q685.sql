WITH return_summary AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        s.s_store_sk,
        s.s_store_name AS store_name,
        r.r_reason_desc AS reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        MIN(d_ret.d_date) AS first_return_date,
        MAX(d_ret.d_date) AS last_return_date,
        cc.cc_employees AS call_center_employees,
        s.s_number_employees AS store_employees,
        cc.cc_sq_ft AS call_center_sq_ft,
        s.s_floor_space AS store_floor_space
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2022
      AND cc.cc_state = s.s_state
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq,
        cc.cc_employees,
        s.s_number_employees,
        cc.cc_sq_ft,
        s.s_floor_space
)
SELECT
    call_center_name,
    store_name,
    reason_desc,
    d_year,
    d_month_seq,
    total_net_loss,
    total_return_amount,
    return_cnt,
    avg_return_quantity,
    first_return_date,
    last_return_date,
    call_center_employees,
    store_employees,
    call_center_sq_ft,
    store_floor_space,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS loss_rank
FROM return_summary
ORDER BY d_year DESC, d_month_seq DESC, total_net_loss DESC
LIMIT 100
