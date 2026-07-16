SELECT
    cc.cc_city,
    s.s_city,
    ws.web_city,
    (d_ret.d_year * 100 + d_ret.d_moy) AS year_month,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(sr.sr_return_amt * (1 + cc.cc_tax_percentage / 100)) AS total_return_with_tax,
    SUM(CASE WHEN sr.sr_return_quantity > 5 THEN sr.sr_return_amt ELSE 0 END) AS high_qty_return_amount
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY
    cc.cc_city,
    s.s_city,
    ws.web_city,
    (d_ret.d_year * 100 + d_ret.d_moy)
