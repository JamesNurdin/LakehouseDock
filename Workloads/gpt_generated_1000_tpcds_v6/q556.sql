SELECT
    w.w_warehouse_name,
    concat(w.w_state, '-', w.w_city) AS region,
    regexp_extract(p.p_promo_id, '[0-9]+') AS promo_number,
    sum(ws.ws_net_profit) AS total_profit,
    count(DISTINCT ws.ws_order_number) AS num_orders
FROM web_sales ws
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
WHERE
    regexp_like(p.p_promo_name, '(?i)discount')
    AND w.w_city LIKE 'San%'
    AND t.t_shift = 'first'
    AND t.t_meal_time = 'breakfast'
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    w.w_city,
    p.p_promo_id
ORDER BY total_profit DESC
LIMIT 100
