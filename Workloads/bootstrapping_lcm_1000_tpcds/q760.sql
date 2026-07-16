WITH returns_summary AS (
    SELECT
        cr.cr_ship_mode_sk,
        dr.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    GROUP BY cr.cr_ship_mode_sk, dr.d_year
)
SELECT
    rs.d_year,
    sm.sm_type,
    sm.sm_carrier,
    sm.sm_contract,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.total_returns,
    rs.avg_return_quantity,
    (rs.total_return_amount - rs.total_net_loss) AS net_revenue,
    CASE
        WHEN sm.sm_type = 'AIR' THEN rs.total_return_amount * 0.95
        WHEN sm.sm_type = 'GROUND' THEN rs.total_return_amount * 0.98
        ELSE rs.total_return_amount
    END AS adjusted_return_amount,
    ROW_NUMBER() OVER (PARTITION BY rs.d_year ORDER BY rs.total_return_amount DESC) AS revenue_rank
FROM returns_summary rs
JOIN ship_mode sm ON rs.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_store ON d_store.d_year = rs.d_year
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_open ON d_open.d_year = rs.d_year
JOIN web_site ws ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk AND d_close.d_year = rs.d_year
WHERE sm.sm_type IS NOT NULL
ORDER BY rs.d_year DESC, net_revenue DESC
LIMIT 100
