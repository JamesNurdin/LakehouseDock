SELECT
    p.p_promo_id,
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amt,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days,
    MIN(d_store_close.d_date) AS store_closed_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    date_diff('day', MIN(d_promo_start.d_date), MAX(d_promo_end.d_date)) AS promo_duration_days,
    SUM(p.p_cost) AS total_promo_cost
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
CROSS JOIN date_dim d_store_close
JOIN store s ON s.s_closed_date_sk = d_store_close.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY p.p_promo_id, s.s_store_id, d_sold.d_year, d_sold.d_month_seq
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
