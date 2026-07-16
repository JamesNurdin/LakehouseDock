SELECT 
    cc.cc_call_center_id,
    cc.cc_name,
    dim_return.d_year,
    dim_return.d_month_seq,
    dim_return.d_current_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_name,
    ws.web_city,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    ROUND(AVG(cr.cr_return_quantity), 2) AS avg_return_qty,
    MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
    MAX(cr.cr_returned_date_sk) AS max_return_date_sk
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dim_return
    ON cr.cr_returned_date_sk = dim_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dim_return.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dim_return.d_date_sk
JOIN date_dim dim_cc_closed
    ON cc.cc_closed_date_sk = dim_cc_closed.d_date_sk
JOIN date_dim dim_cc_open
    ON cc.cc_open_date_sk = dim_cc_open.d_date_sk
JOIN date_dim dim_ws_close
    ON ws.web_close_date_sk = dim_ws_close.d_date_sk
WHERE dim_return.d_year = 2001
  AND cc.cc_country = 'United States'
  AND ws.web_state = s.s_state
GROUP BY 
    cc.cc_call_center_id,
    cc.cc_name,
    dim_return.d_year,
    dim_return.d_month_seq,
    dim_return.d_current_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_name,
    ws.web_city
ORDER BY total_return_amount DESC
LIMIT 100
