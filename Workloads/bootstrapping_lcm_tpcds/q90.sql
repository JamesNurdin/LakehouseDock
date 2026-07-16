SELECT
    s.s_store_name,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(ws.ws_ext_sales_price) - COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS net_sales_after_returns,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_quantity) + SUM(cr.cr_return_quantity) AS total_return_quantity,
    CASE WHEN SUM(ws.ws_quantity) > 0 THEN (SUM(wr.wr_return_quantity) + SUM(cr.cr_return_quantity)) / SUM(ws.ws_quantity) ELSE 0 END AS return_quantity_ratio,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    AVG(date_diff('day', d_store.d_date, d_ws_ship.d_date)) AS avg_shipping_delay_days,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
FROM
    store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_store.d_date_sk
    LEFT JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_store.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_store.d_date_sk
WHERE
    d_store.d_year = 2022
GROUP BY
    s.s_store_name,
    d_store.d_year,
    d_store.d_month_seq
ORDER BY
    total_net_profit DESC
LIMIT 100
