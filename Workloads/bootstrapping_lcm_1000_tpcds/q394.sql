WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        p.p_response_target,
        sm.sm_type AS ship_mode_type,
        sm.sm_carrier,
        d_p_start.d_date AS promo_start_date,
        d_p_end.d_date AS promo_end_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        date_diff('day', d_sold.d_date, d_ship.d_date) AS ship_delay_days
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
),
agg AS (
    SELECT
        sold_year,
        sold_month_seq,
        p_promo_name,
        ship_mode_type,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales_amount,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ship_delay_days) AS avg_ship_delay_days,
        DATE_DIFF('day', MIN(promo_start_date), MAX(promo_end_date)) AS promo_duration_days,
        COUNT(DISTINCT s_store_id) AS num_stores_closed_on_sale_date,
        SUM(CASE WHEN p_discount_active = 'Y' THEN ws_quantity ELSE 0 END) AS quantity_discounted,
        SUM(p_cost * ws_quantity) AS total_promotion_cost,
        AVG(ws_sales_price) AS avg_sales_price
    FROM sales
    WHERE sold_year = 2022
    GROUP BY
        sold_year,
        sold_month_seq,
        p_promo_name,
        ship_mode_type
)
SELECT
    sold_year,
    sold_month_seq,
    p_promo_name,
    ship_mode_type,
    num_orders,
    total_quantity,
    total_sales_amount,
    total_net_profit,
    avg_ship_delay_days,
    promo_duration_days,
    num_stores_closed_on_sale_date,
    quantity_discounted,
    total_promotion_cost,
    avg_sales_price,
    DENSE_RANK() OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
