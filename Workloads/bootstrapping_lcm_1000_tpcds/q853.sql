WITH returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_store_sk AS s_store_sk,
        s.s_state,
        s.s_city,
        w.w_warehouse_name AS warehouse_name,
        w.w_state AS warehouse_state,
        t.t_hour,
        t.t_meal_time,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE
            WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_return_amount) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_amount_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND w.w_state = 'CA'
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        s.s_store_sk,
        s.s_state,
        s.s_city,
        w.w_warehouse_name,
        w.w_state,
        t.t_hour,
        t.t_meal_time
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    ra.d_year,
    ra.d_quarter_name,
    ra.s_state,
    ra.s_city,
    ra.warehouse_name,
    ra.warehouse_state,
    ra.t_hour,
    ra.t_meal_time,
    ra.total_returns,
    ra.total_quantity,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.avg_return_amount,
    ra.return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY ra.s_store_sk ORDER BY ra.total_return_amount DESC) AS rn_store_by_return_amount
FROM returns_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 100
