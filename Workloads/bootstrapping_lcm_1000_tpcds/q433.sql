WITH agg_returns AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        d.d_year,
        sm.sm_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND sm.sm_type IS NOT NULL
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d.d_year,
        sm.sm_type
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    ar.s_store_id,
    ar.s_city,
    ar.s_state,
    ar.d_year,
    ar.sm_type,
    ar.total_net_loss,
    ar.total_return_amount,
    ar.avg_return_qty,
    ar.return_count,
    ROW_NUMBER() OVER (PARTITION BY ar.d_year ORDER BY ar.total_net_loss DESC) AS net_loss_rank
FROM agg_returns ar
ORDER BY ar.d_year, ar.total_net_loss DESC
LIMIT 100
