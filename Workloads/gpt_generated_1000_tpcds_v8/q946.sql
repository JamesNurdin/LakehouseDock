WITH sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
),

store_base AS (
    SELECT
        td.t_hour,
        i.i_class,
        r.r_reason_desc,
        sr.sr_net_loss,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        seq_tbl.seq
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN sampled_items i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN (SELECT 1 AS seq UNION ALL SELECT 2 AS seq) AS seq_tbl
    WHERE td.t_hour BETWEEN 8 AND 18
      AND i.i_class = 'furniture'
      AND hd.hd_vehicle_count > 1
      AND ib.ib_lower_bound >= 30000
      AND r.r_reason_desc = 'Customer Not Satisfied'
),

store_agg AS (
    SELECT
        t_hour,
        i_class,
        r_reason_desc,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt
    FROM store_base
    GROUP BY ROLLUP(t_hour, i_class, r_reason_desc)
),

catalog_base AS (
    SELECT
        td.t_hour,
        i.i_class,
        cr.cr_net_loss,
        cc.cc_manager,
        cp.cp_department,
        sm.sm_type,
        r.r_reason_desc,
        hd.hd_vehicle_count,
        ib.ib_upper_bound
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN sampled_items i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND cc.cc_manager LIKE '%James%'
      AND cp.cp_department = 'DEPARTMENT'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Damaged'
),

catalog_agg AS (
    SELECT
        t_hour,
        i_class,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt
    FROM catalog_base
    GROUP BY CUBE(t_hour, i_class)
),

final_agg AS (
    SELECT
        COALESCE(s.t_hour, c.t_hour) AS hour,
        COALESCE(s.i_class, c.i_class) AS item_class,
        s.r_reason_desc,
        s.total_net_loss AS store_net_loss,
        c.total_net_loss AS catalog_net_loss,
        (COALESCE(s.total_net_loss, 0) + COALESCE(c.total_net_loss, 0)) AS combined_net_loss
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c
        ON s.t_hour = c.t_hour AND s.i_class = c.i_class
)
SELECT
    hour,
    item_class,
    r_reason_desc,
    store_net_loss,
    catalog_net_loss,
    combined_net_loss,
    (SELECT AVG(sr_net_loss) FROM store_returns) AS avg_store_loss
FROM final_agg
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td2.t_hour = final_agg.hour
      AND wr.wr_net_loss > final_agg.combined_net_loss
)
ORDER BY hour NULLS LAST, item_class
LIMIT 100
