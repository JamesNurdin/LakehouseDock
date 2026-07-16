SELECT
    p.p_promo_id,
    d_sold.d_current_month,
    sm.sm_carrier,
    st.s_state,
    SUM(ws.ws_net_profit)          AS total_net_profit,
    SUM(ws.ws_quantity)            AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_sales_price)         AS avg_sales_price
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_p_start
    ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
  AND d_sold.d_date_sk BETWEEN d_p_start.d_date_sk AND d_p_end.d_date_sk
GROUP BY
    p.p_promo_id,
    d_sold.d_current_month,
    sm.sm_carrier,
    st.s_state
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
