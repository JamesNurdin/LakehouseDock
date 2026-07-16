WITH returns_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promos_active
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
        AND p.p_end_date_sk >= d.d_date_sk
    WHERE
        d.d_year BETWEEN 2010 AND 2020
        AND sm.sm_type IN ('AIR', 'GROUND')
        AND t.t_shift = 'Evening'
        AND cr.cr_warehouse_sk IN (7, 11, 14)
        AND cr.cr_return_quantity > 1
    GROUP BY
        d.d_year,
        d.d_month_seq,
        sm.sm_type
    HAVING
        SUM(cr.cr_return_amount) > 1000
)
SELECT
    rs.d_year,
    rs.d_month_seq,
    rs.sm_type,
    rs.total_returns,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.avg_return_quantity,
    rs.distinct_promos_active,
    RANK() OVER (PARTITION BY rs.d_year, rs.d_month_seq ORDER BY rs.total_return_amount DESC) AS ship_mode_rank
FROM returns_summary rs
ORDER BY rs.total_return_amount DESC
LIMIT 100
