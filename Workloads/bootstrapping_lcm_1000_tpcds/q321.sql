SELECT
    cc.cc_name,
    cc.cc_division,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    s.s_store_name,
    s.s_city AS store_city,
    d_store_closed.d_year AS store_closed_year,
    ws.web_name,
    ws.web_city,
    d_web_open.d_year AS web_open_year,
    d_web_close.d_year AS web_close_year,
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_transactions
FROM
    call_center cc
    JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_web_open
        ON ws.web_open_date_sk = d_web_open.d_date_sk
    JOIN date_dim d_web_close
        ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE
    d_ret.d_year = 2022
GROUP BY
    cc.cc_name,
    cc.cc_division,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_year,
    ws.web_name,
    ws.web_city,
    d_web_open.d_year,
    d_web_close.d_year,
    d_ret.d_year,
    d_ret.d_quarter_name
ORDER BY
    total_net_loss DESC
LIMIT 100
