SELECT
    d_ret.d_year AS return_year,
    w.w_state AS warehouse_state,
    cc.cc_division_name AS call_center_division,
    s.s_city AS store_city,
    concat(
        CASE
            WHEN w.w_warehouse_sq_ft > 500000 THEN 'mega'
            WHEN w.w_warehouse_sq_ft > 200000 THEN 'large'
            ELSE 'small'
        END,
        '-',
        CASE WHEN mod(w.w_warehouse_sq_ft, 2) = 0 THEN 'even' ELSE 'odd' END
    ) AS warehouse_category,
    count(cr.cr_order_number) AS total_returns,
    sum(cr.cr_return_amount) AS total_return_amount,
    sum(cr.cr_net_loss) AS total_net_loss,
    avg(cr.cr_return_tax) AS avg_return_tax,
    sum(cr.cr_fee) AS total_fee,
    sum(cr.cr_return_quantity) AS total_quantity,
    max(d_ret.d_date) AS latest_return_date,
    min(d_ret.d_date) AS earliest_return_date,
    round(sum(cr.cr_return_amount) / nullif(sum(cr.cr_return_quantity), 0), 2) AS avg_return_amount_per_item
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    w.w_state,
    cc.cc_division_name,
    s.s_city,
    concat(
        CASE
            WHEN w.w_warehouse_sq_ft > 500000 THEN 'mega'
            WHEN w.w_warehouse_sq_ft > 200000 THEN 'large'
            ELSE 'small'
        END,
        '-',
        CASE WHEN mod(w.w_warehouse_sq_ft, 2) = 0 THEN 'even' ELSE 'odd' END
    )
