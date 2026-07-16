SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_country,
    dd_open.d_year AS cc_open_year,
    dd_cc.d_year AS cc_closed_year,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_country,
    dd_store.d_year AS store_closed_year,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    dd_ret.d_year AS return_year,
    dd_ret.d_moy AS return_month,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM web_returns wr
JOIN date_dim dd_ret
    ON wr.wr_returned_date_sk = dd_ret.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = dd_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = dd_ret.d_date_sk
JOIN date_dim dd_cc
    ON cc.cc_closed_date_sk = dd_cc.d_date_sk
JOIN date_dim dd_open
    ON cc.cc_open_date_sk = dd_open.d_date_sk
JOIN date_dim dd_store
    ON s.s_closed_date_sk = dd_store.d_date_sk
GROUP BY
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_country,
    dd_open.d_year,
    dd_cc.d_year,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_country,
    dd_store.d_year,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    i.i_current_price,
    dd_ret.d_year,
    dd_ret.d_moy
ORDER BY total_return_amount DESC
LIMIT 100
