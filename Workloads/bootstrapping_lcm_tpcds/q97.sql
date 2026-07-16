SELECT
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_return_net_loss,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    CASE
        WHEN SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0 THEN 'Loss'
        ELSE 'Gain'
    END AS overall_return_status,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM catalog_returns cr
INNER JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
INNER JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
INNER JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_sales_amount DESC
LIMIT 100
