WITH base AS (
    SELECT
        d1.d_date,
        t1.t_hour,
        cc.cc_name,
        cp.cp_catalog_number,
        sm.sm_type,
        sr.sr_store_sk,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d1.d_date_sk
                              AND cr.cr_returned_time_sk = t1.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d1.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cc.cc_gmt_offset = -5.00
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_start_date_sk = d1.d_date_sk
            AND p.p_end_date_sk = d1.d_date_sk
            AND p.p_channel_event = 'N'
      )
    GROUP BY d1.d_date, t1.t_hour, cc.cc_name, cp.cp_catalog_number, sm.sm_type, sr.sr_store_sk
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    d_date,
    t_hour,
    cc_name,
    cp_catalog_number,
    sm_type,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY total_net_loss DESC) AS rn_store
FROM base
ORDER BY total_net_loss DESC
LIMIT 100
