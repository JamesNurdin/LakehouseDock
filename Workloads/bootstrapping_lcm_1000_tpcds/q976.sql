SELECT
    w.w_warehouse_name,
    d_sales.d_year AS sales_year,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_sales_discount,
    SUM(ws.ws_ext_list_price) AS total_list_price,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid_inc_tax) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
    AVG(CASE WHEN ws.ws_coupon_amt > 0 THEN ws.ws_coupon_amt END) AS avg_coupon_amt,
    COUNT(CASE WHEN cr.cr_return_quantity > 0 THEN 1 END) AS num_return_items,
    SUM(ws.ws_ext_tax) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS tax_rate,
    CASE
        WHEN SUM(ws.ws_net_paid_inc_tax) > 0 THEN SUM(cr.cr_net_loss) / SUM(ws.ws_net_paid_inc_tax)
        ELSE NULL
    END AS loss_ratio,
    MIN(d_ship.d_month_seq) AS min_ship_month
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
GROUP BY w.w_warehouse_name, d_sales.d_year, s.s_state
HAVING SUM(ws.ws_net_paid_inc_tax) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
