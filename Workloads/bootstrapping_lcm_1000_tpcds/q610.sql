WITH store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_market_desc,
        s.s_state,
        s.s_closed_date_sk,
        dsc.d_date AS store_closed_date
    FROM store s
    JOIN date_dim dsc ON s.s_closed_date_sk = dsc.d_date_sk
)
SELECT
    cd.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    cd.cd_education_status AS bill_education,
    cd_ship.cd_education_status AS ship_education,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name AS promo_name,
    p.p_channel_demo AS promo_channel_demo,
    p.p_discount_active AS promo_discount_active,
    s.s_market_desc AS market_desc,
    s.s_state AS market_state,
    s.store_closed_date,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_ship.d_date) AS last_ship_date,
    MIN(d_p_start.d_date) AS promo_start_date,
    MAX(d_p_end.d_date) AS promo_end_date
FROM web_sales ws
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
CROSS JOIN store_dates s
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    cd.cd_gender,
    cd_ship.cd_gender,
    cd.cd_education_status,
    cd_ship.cd_education_status,
    d_sold.d_year,
    d_ship.d_month_seq,
    p.p_promo_name,
    p.p_channel_demo,
    p.p_discount_active,
    s.s_market_desc,
    s.s_state,
    s.store_closed_date
ORDER BY total_net_profit DESC
LIMIT 100
