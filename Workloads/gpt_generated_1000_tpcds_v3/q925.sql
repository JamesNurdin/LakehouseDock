WITH joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        dr.d_date,
        dr.d_year,
        sr.sr_net_loss,
        cr.cr_net_loss,
        t.t_hour,
        cp.cp_department,
        p.p_discount_active,
        ws.web_country
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = dr.d_date_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE dr.d_year = 2001
      AND s.s_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND ws.web_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    store_name,
    state,
    return_date,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_loss DESC) AS state_store_rank,
    AVG(total_net_loss) OVER (PARTITION BY state ORDER BY return_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day_net_loss
FROM (
    SELECT
        s_store_name AS store_name,
        s_state AS state,
        d_date AS return_date,
        SUM(sr_net_loss + cr_net_loss) AS total_net_loss
    FROM joined_data
    GROUP BY s_store_name, s_state, d_date
) agg
ORDER BY total_net_loss DESC
LIMIT 100
