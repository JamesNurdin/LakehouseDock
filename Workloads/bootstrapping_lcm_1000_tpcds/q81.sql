SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_id,
    a.s_city,
    a.w_warehouse_name,
    a.w_state,
    a.total_net_loss,
    a.total_return_amount,
    a.return_count,
    a.avg_return_quantity,
    a.net_loss_category,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        w.w_warehouse_name,
        w.w_state,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        CASE 
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS net_loss_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND w.w_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_city, w.w_warehouse_name, w.w_state
) a
ORDER BY a.total_net_loss DESC
LIMIT 100
