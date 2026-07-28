WITH 
    -- Aliases for date_dim are used multiple times to join different facts
    d_sr AS (SELECT * FROM date_dim),
    d_cr AS (SELECT * FROM date_dim),
    d_wr AS (SELECT * FROM date_dim),
    -- Aliases for time_dim
    td_sr AS (SELECT * FROM time_dim),
    td_cr AS (SELECT * FROM time_dim),
    td_wr AS (SELECT * FROM time_dim),
    -- Alias for reason used for web returns
    r_wr AS (SELECT * FROM reason)
SELECT
    cc.cc_division_name,
    cp.cp_catalog_page_number,
    sm.sm_type,
    w.w_state,
    r.r_reason_desc,
    d_sr.d_year,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss
FROM
    store_returns sr
    JOIN d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    -- Catalog returns linked through the same customer (refunded)
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- Web returns linked through the same customer (refunded)
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- Promotion joined via the start‑date surrogate key to the store‑return date dimension
    JOIN promotion p ON p.p_start_date_sk = d_sr.d_date_sk
WHERE
    d_sr.d_year = 2001
GROUP BY
    cc.cc_division_name,
    cp.cp_catalog_page_number,
    sm.sm_type,
    w.w_state,
    r.r_reason_desc,
    d_sr.d_year
ORDER BY
    total_net_loss DESC
LIMIT 100
