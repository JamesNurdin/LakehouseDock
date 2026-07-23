WITH cr_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cp.cp_department AS department,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name AS warehouse_name,
        td_cr.t_hour AS t_hour,
        NULL AS minute,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt,
        hd_refunded.hd_vehicle_count AS refunded_vehicle_count,
        hd_returning.hd_vehicle_count AS returning_vehicle_count
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
    GROUP BY
        cr.cr_returned_date_sk,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        td_cr.t_hour,
        hd_refunded.hd_vehicle_count,
        hd_returning.hd_vehicle_count
),
sr_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        'STORE' AS department,
        NULL AS ship_mode_type,
        NULL AS warehouse_name,
        td_sr.t_hour AS t_hour,
        td_sr2.t_minute AS minute,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt,
        hd_sr.hd_vehicle_count AS sr_vehicle_count,
        hd_sr2.hd_vehicle_count AS sr_vehicle_count2
    FROM store_returns sr
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN time_dim td_sr2
        ON sr.sr_return_time_sk = td_sr2.t_time_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN household_demographics hd_sr2
        ON sr.sr_hdemo_sk = hd_sr2.hd_demo_sk
    WHERE td_sr.t_hour BETWEEN 8 AND 20
    GROUP BY
        sr.sr_returned_date_sk,
        td_sr.t_hour,
        td_sr2.t_minute,
        hd_sr.hd_vehicle_count,
        hd_sr2.hd_vehicle_count
),
combined AS (
    SELECT DISTINCT
        date_sk,
        department,
        ship_mode_type,
        warehouse_name,
        t_hour,
        minute,
        total_return_amount,
        total_net_loss
    FROM cr_agg
    UNION ALL
    SELECT DISTINCT
        date_sk,
        department,
        ship_mode_type,
        warehouse_name,
        t_hour,
        minute,
        total_return_amount,
        total_net_loss
    FROM sr_agg
)
SELECT
    date_sk,
    department,
    COALESCE(ship_mode_type, 'N/A') AS ship_mode_type,
    COALESCE(warehouse_name, 'N/A') AS warehouse_name,
    t_hour,
    minute,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(total_net_loss) AS sum_net_loss,
    COUNT(*) AS rows,
    CASE
        WHEN SUM(total_net_loss) > 10000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category
FROM combined
WHERE date_sk IS NOT NULL
GROUP BY
    date_sk,
    department,
    ship_mode_type,
    warehouse_name,
    t_hour,
    minute
HAVING SUM(total_return_amount) > 5000
ORDER BY sum_net_loss DESC
LIMIT 100
