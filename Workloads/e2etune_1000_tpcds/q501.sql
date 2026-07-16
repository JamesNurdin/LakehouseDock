SELECT
    p.p_promo_name,
    t.t_hour,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt_inc_tax, 0))) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM web_sales ws
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
WHERE p.p_discount_active = 'Y'
  AND c.c_birth_month = 7
  AND hd.hd_vehicle_count >= 2
GROUP BY p.p_promo_name, t.t_hour
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 50
