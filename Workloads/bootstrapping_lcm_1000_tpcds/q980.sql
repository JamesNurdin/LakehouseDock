SELECT
    d_ret.d_year AS return_year,
    (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month,
    w_cr.w_warehouse_name,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price - ws.ws_coupon_amt) AS net_sales_after_coupons,
    SUM(ws.ws_ext_sales_price) - SUM(cr.cr_return_amount) AS net_sales_minus_returns,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
        ELSE (SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)) * 100
    END AS profit_margin_pct,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_quantity ELSE 0 END) AS total_return_quantity
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w_cr.w_warehouse_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 1998 AND 2000
GROUP BY
    ROLLUP (d_ret.d_year, w_cr.w_warehouse_name, s.s_state),
    d_ret.d_month_seq
HAVING COUNT(*) > 0
ORDER BY return_year, year_month, w_cr.w_warehouse_name
