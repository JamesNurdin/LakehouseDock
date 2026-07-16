SELECT
    dr.d_year,
    dr.d_month_seq,
    s.s_store_id,
    r.r_reason_desc,
    COUNT(*) AS transaction_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_paid) AS total_sales_net_paid,
    AVG(date_diff('day', dr.d_date, ds.d_date)) AS avg_days_between_return_and_ship
FROM catalog_returns cr
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON ws.ws_ship_date_sk = ds.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
WHERE dr.d_year >= 1998
GROUP BY dr.d_year, dr.d_month_seq, s.s_store_id, r.r_reason_desc
ORDER BY dr.d_year DESC, total_return_amount DESC
LIMIT 100
