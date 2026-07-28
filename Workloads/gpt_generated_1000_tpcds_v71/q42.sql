WITH agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        MAX(cr.cr_net_loss) AS max_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_meal_time = 'dinner'
        AND cp.cp_type = 'catalog'
        AND ws.web_country = 'United States'
    GROUP BY
        d.d_year,
        s.s_store_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name
)
SELECT
    d_year,
    s_store_name,
    cp_department,
    sm_type,
    w_warehouse_name,
    total_return_amount,
    avg_return_tax,
    distinct_orders,
    max_net_loss,
    SUM(total_return_amount) OVER (PARTITION BY s_store_name ORDER BY d_year ROWS UNBOUNDED PRECEDING) AS cumulative_return_by_store
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
