SELECT
    p.p_promo_id,
    p.p_promo_name,
    promo_start_dd.d_date AS promo_start_date,
    promo_end_dd.d_date AS promo_end_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    sold_dd.d_year AS sold_year,
    sold_dd.d_month_seq AS sold_month,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    bill_hd.hd_income_band_sk AS bill_income_band,
    ship_hd.hd_income_band_sk AS ship_income_band
FROM web_sales ws
JOIN date_dim sold_dd
    ON ws.ws_sold_date_sk = sold_dd.d_date_sk
JOIN date_dim ship_dd
    ON ws.ws_ship_date_sk = ship_dd.d_date_sk
JOIN household_demographics bill_hd
    ON ws.ws_bill_hdemo_sk = bill_hd.hd_demo_sk
JOIN household_demographics ship_hd
    ON ws.ws_ship_hdemo_sk = ship_hd.hd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim promo_start_dd
    ON p.p_start_date_sk = promo_start_dd.d_date_sk
JOIN date_dim promo_end_dd
    ON p.p_end_date_sk = promo_end_dd.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = promo_end_dd.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    promo_start_dd.d_date,
    promo_end_dd.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    sold_dd.d_year,
    sold_dd.d_month_seq,
    bill_hd.hd_income_band_sk,
    ship_hd.hd_income_band_sk
ORDER BY total_net_profit DESC
LIMIT 10
