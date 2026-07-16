WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_carrier,
        s.s_state,
        w_open.web_state AS open_state,
        w_close.web_state AS close_state,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w_open ON w_open.web_open_date_sk = d.d_date_sk
    JOIN web_site w_close ON w_close.web_close_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2005
    GROUP BY d.d_year, d.d_month_seq, sm.sm_carrier, s.s_state, w_open.web_state, w_close.web_state
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.sm_carrier,
    a.s_state,
    a.open_state,
    a.close_state,
    a.distinct_orders,
    a.total_return_qty,
    a.total_return_amount,
    a.total_return_tax,
    a.total_fee,
    a.total_net_loss,
    a.avg_return_amount,
    CASE
        WHEN a.total_net_loss > 10000 THEN 'HIGH'
        WHEN a.total_net_loss > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS loss_rank_by_year
FROM agg a
ORDER BY a.d_year, loss_rank_by_year
LIMIT 100
