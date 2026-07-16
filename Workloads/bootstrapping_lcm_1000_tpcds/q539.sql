SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_discount_active,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_bill.cd_credit_rating AS bill_credit_rating,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    date_diff('day', d_sold.d_date, d_ship.d_date) AS shipping_delay_days,
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    sum(ws.ws_ext_sales_price) AS total_sales,
    sum(ws.ws_net_profit) AS total_profit,
    sum(ws.ws_coupon_amt) AS total_coupons,
    avg(ws.ws_quantity) AS avg_quantity,
    count(DISTINCT ws.ws_order_number) AS distinct_orders,
    sum(ws.ws_net_profit) / nullif(sum(ws.ws_ext_sales_price), 0) AS profit_margin
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_year >= 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_discount_active,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_bill.cd_credit_rating,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status,
    date_diff('day', d_sold.d_date, d_ship.d_date),
    date_diff('day', d_promo_start.d_date, d_promo_end.d_date)
