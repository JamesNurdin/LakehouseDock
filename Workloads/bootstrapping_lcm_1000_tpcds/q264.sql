WITH return_summary AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        s.s_store_name,
        s.s_state,
        SUM(cr.cr_net_loss)                AS total_net_loss,
        SUM(cr.cr_return_amount)           AS total_return_amount,
        SUM(cr.cr_return_quantity)         AS total_return_qty,
        AVG(cr.cr_return_tax)              AS avg_return_tax,
        COUNT(*)                           AS return_rows,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        s.s_store_name,
        s.s_state
)
SELECT
    d_year,
    d_quarter_seq,
    i_category,
    i_brand,
    sm_type,
    s_store_name,
    s_state,
    total_net_loss,
    total_return_amount,
    total_return_qty,
    avg_return_tax,
    distinct_orders,
    RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_net_loss DESC) AS net_loss_rank
FROM return_summary
ORDER BY d_year DESC, d_quarter_seq DESC, net_loss_rank
LIMIT 100
