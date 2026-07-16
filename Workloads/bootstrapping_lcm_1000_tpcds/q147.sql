SELECT
    r.r_reason_desc AS reason_desc,
    s.s_store_name AS store_name,
    d.d_year AS return_year,
    shd.d_year AS ship_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)
        ELSE 0
    END AS profit_margin,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN SUM(cr.cr_net_loss) / SUM(ws.ws_net_profit)
        ELSE NULL
    END AS loss_to_profit_ratio
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim shd ON ws.ws_ship_date_sk = shd.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    r.r_reason_desc,
    s.s_store_name,
    d.d_year,
    shd.d_year
ORDER BY total_net_loss DESC
LIMIT 100
