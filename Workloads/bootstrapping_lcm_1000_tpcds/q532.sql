SELECT 
    year,
    month_seq,
    ship_type,
    state,
    hour,
    return_cnt,
    total_return_amount,
    total_return_tax,
    avg_return_qty,
    total_net_loss,
    CASE 
        WHEN total_return_amount > 5000 THEN 'HIGH' 
        ELSE 'LOW' 
    END AS amount_bucket
FROM (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        sm.sm_type AS ship_type,
        s.s_state AS state,
        t.t_hour AS hour,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d 
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t 
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm 
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s 
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY 
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_state,
        t.t_hour
    HAVING COUNT(*) > 10
) AS agg
ORDER BY total_return_amount DESC
LIMIT 100
