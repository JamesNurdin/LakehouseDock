WITH cat_ret_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_returned_date_sk,
        COUNT(DISTINCT cr.cr_order_number) AS cat_order_cnt,
        SUM(cr.cr_return_amount) AS cat_total_return,
        SUM(cr.cr_net_loss) AS cat_total_net_loss,
        SUM(cr.cr_return_quantity) AS cat_total_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk, cr.cr_returned_date_sk
), web_ret_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
        SUM(wr.wr_return_amt) AS web_total_return,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        SUM(wr.wr_return_quantity) AS web_total_quantity
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    cc.cc_call_center_sk,
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_date AS return_date,
    d_closed.d_date AS call_center_closed_date,
    d_open.d_date AS call_center_open_date,
    s.s_store_name,
    s.s_state AS store_state,
    s.s_floor_space,
    cat_ret.cat_order_cnt,
    cat_ret.cat_total_return,
    cat_ret.cat_total_net_loss,
    cat_ret.cat_total_quantity,
    cat_ret.cat_total_return - cat_ret.cat_total_net_loss AS cat_return_minus_net_loss,
    web_ret.web_order_cnt,
    web_ret.web_total_return,
    web_ret.web_total_net_loss,
    web_ret.web_total_quantity,
    web_ret.web_total_return - web_ret.web_total_net_loss AS web_return_minus_net_loss
FROM call_center cc
JOIN cat_ret_agg cat_ret
    ON cat_ret.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_return
    ON cat_ret.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_ret_agg web_ret
    ON web_ret.wr_returned_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2022
ORDER BY cat_ret.cat_total_return DESC
LIMIT 100
