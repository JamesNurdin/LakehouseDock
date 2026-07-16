WITH sales_agg AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_store.d_year AS store_closed_year,
        p.p_promo_id AS p_promo_id,
        p.p_promo_name AS p_promo_name,
        p.p_purpose AS p_purpose,
        cd_bill.cd_gender AS bill_gender,
        cd_bill.cd_education_status AS bill_education_status,
        cd_ship.cd_gender AS ship_gender,
        cd_ship.cd_marital_status AS ship_marital_status,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_sales_price) AS total_sales_price,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amt
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    CROSS JOIN store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_store.d_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_purpose,
        cd_bill.cd_gender,
        cd_bill.cd_education_status,
        cd_ship.cd_gender,
        cd_ship.cd_marital_status,
        d_sold.d_year,
        d_ship.d_year
)
SELECT
    s_store_id,
    s_city,
    s_state,
    store_closed_year,
    p_promo_id,
    p_promo_name,
    p_purpose,
    bill_gender,
    bill_education_status,
    ship_gender,
    ship_marital_status,
    sold_year,
    ship_year,
    order_cnt,
    total_net_profit,
    total_sales_price,
    avg_coupon_amt,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
