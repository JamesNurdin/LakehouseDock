WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_wholesale_cost,
        w.w_warehouse_name,
        w.w_state,
        s.s_state
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    CASE WHEN i_current_price > i_wholesale_cost THEN 'Profit' ELSE 'Loss' END AS price_margin,
    CASE WHEN w_state = s_state THEN 'SameState' ELSE 'DiffState' END AS state_relation,
    w_warehouse_name,
    s_state,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_quantity,
    AVG(cr_net_loss) AS avg_net_loss,
    SUM(cr_fee) AS total_fee
FROM joined_data
GROUP BY
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    CASE WHEN i_current_price > i_wholesale_cost THEN 'Profit' ELSE 'Loss' END,
    CASE WHEN w_state = s_state THEN 'SameState' ELSE 'DiffState' END,
    w_warehouse_name,
    s_state
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
