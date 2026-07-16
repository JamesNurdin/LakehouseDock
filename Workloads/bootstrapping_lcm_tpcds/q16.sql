WITH sales_summary AS (
    SELECT
        s.s_division_id,
        s.s_store_name,
        s.s_market_desc,
        s.s_state,
        s.s_floor_space,
        d_sold.d_year AS sold_year,
        d_sold.d_moy AS sold_month,
        d_sold.d_day_name AS sold_day_name,
        d_ship.d_year AS ship_year,
        d_ship.d_moy AS ship_month,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_lag_days,
        i.inv_item_sk,
        AVG(i.inv_quantity_on_hand) AS avg_quantity_on_hand,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        MAX(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY
        s.s_division_id,
        s.s_store_name,
        s.s_market_desc,
        s.s_state,
        s.s_floor_space,
        d_sold.d_year,
        d_sold.d_moy,
        d_sold.d_day_name,
        d_ship.d_year,
        d_ship.d_moy,
        i.inv_item_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost
)
SELECT
    s_division_id,
    s_store_name,
    sold_year,
    sold_month,
    sold_day_name,
    ship_year,
    ship_month,
    avg_shipping_lag_days,
    inv_item_sk,
    avg_quantity_on_hand,
    total_quantity,
    total_sales,
    total_net_profit,
    promo_duration_days,
    p_promo_name,
    p_discount_active,
    p_cost,
    RANK() OVER (PARTITION BY s_division_id ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_summary
ORDER BY total_net_profit DESC
LIMIT 100
