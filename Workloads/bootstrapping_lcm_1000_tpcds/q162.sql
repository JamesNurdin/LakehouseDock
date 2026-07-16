SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date AS store_closed_date,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(i.i_current_price) AS avg_item_price,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY SUM(cr.cr_return_amount) DESC) AS rank_by_return_amount
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    d_cc_closed.d_date,
    d_cc_open.d_date
ORDER BY total_return_amount DESC
LIMIT 100
