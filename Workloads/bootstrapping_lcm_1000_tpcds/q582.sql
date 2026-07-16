SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sr.d_year AS return_year,
    d_sr.d_month_seq AS return_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_revenue,
    SUM(ws.ws_ext_discount_amt) AS total_web_discount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_return_net_loss,
    MAX(d_ws_ship.d_date) AS latest_ship_date,
    MIN(d_store_closed.d_date) AS store_closed_date
FROM
    store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_sr.d_date_sk
    LEFT JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    s.s_state = 'CA'
    AND d_sr.d_year BETWEEN 2000 AND 2002
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sr.d_year,
    d_sr.d_month_seq
HAVING
    SUM(ws.ws_net_paid_inc_tax) > 10000
ORDER BY
    total_web_profit DESC
LIMIT 100
