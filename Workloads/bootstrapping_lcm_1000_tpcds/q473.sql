SELECT
    s.s_store_id,
    d_cr.d_year,
    CASE WHEN d_cr.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_net_loss) AS total_store_loss,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_profit) AS total_web_profit,
    (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) AS net_sales,
    AVG(ws.ws_coupon_amt) FILTER (WHERE ws.ws_coupon_amt > 0) AS avg_coupon_amt,
    SUM(cr.cr_fee) AS total_credit_fees,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    AVG(date_diff('day', d_cr.d_date, d_ws_ship.d_date)) AS avg_days_return_to_ship,
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) / NULLIF(SUM(ws.ws_net_profit), 0) AS loss_to_profit_ratio
FROM catalog_returns cr
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cr.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
WHERE d_cr.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    d_cr.d_year,
    CASE WHEN d_cr.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
ORDER BY total_web_profit DESC
LIMIT 100
