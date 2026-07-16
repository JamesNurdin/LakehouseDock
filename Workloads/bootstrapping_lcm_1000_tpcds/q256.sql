WITH returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name,
        s.s_city AS store_city,
        w.w_warehouse_name,
        w.w_city AS warehouse_city,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        sm.sm_type,
        sm.sm_carrier,
        s.s_store_name,
        s.s_city,
        w.w_warehouse_name,
        w.w_city
)
SELECT
    d_year,
    d_quarter_name,
    sm_type,
    sm_carrier,
    s_store_name,
    store_city,
    w_warehouse_name,
    warehouse_city,
    total_net_loss,
    total_return_amount,
    avg_return_quantity,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank_year
FROM returns_agg
ORDER BY d_year, total_net_loss DESC
LIMIT 100
