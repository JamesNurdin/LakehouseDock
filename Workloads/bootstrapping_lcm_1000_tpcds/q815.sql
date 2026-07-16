WITH store_monthly_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        sm.sm_type,
        COUNT(cr.cr_order_number) AS returns_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        SUM(cr.cr_return_quantity) AS total_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
    GROUP BY d.d_year, d.d_month_seq, s.s_store_sk, s.s_store_name, s.s_state, sm.sm_type
),
ranked_stores AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        s_store_name,
        s_state,
        sm_type,
        returns_cnt,
        total_net_loss,
        avg_return_tax,
        total_ship_cost,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS rn
    FROM store_monthly_summary
)
SELECT
    d_year,
    d_month_seq,
    s_store_sk,
    s_store_name,
    s_state,
    sm_type,
    returns_cnt,
    total_net_loss,
    avg_return_tax,
    total_ship_cost,
    total_quantity
FROM ranked_stores
WHERE rn <= 5
ORDER BY d_year DESC, d_month_seq, total_net_loss DESC
LIMIT 100
