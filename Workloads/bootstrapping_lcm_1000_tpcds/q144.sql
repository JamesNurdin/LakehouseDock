SELECT
    d.d_year,
    d.d_month_seq,
    d.d_date,
    w.w_warehouse_name,
    w.w_state,
    s.s_store_id,
    s.s_city,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN
            (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS profit_margin_after_returns
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2018 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_date,
    w.w_warehouse_name,
    w.w_state,
    s.s_store_id,
    s.s_city
ORDER BY d.d_date, w.w_warehouse_name
LIMIT 100
