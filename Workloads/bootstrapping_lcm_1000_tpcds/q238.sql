WITH promo_store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year AS sold_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_email,
        p.p_discount_active,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
        AVG(DATE_DIFF('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_email,
        p.p_discount_active
)
SELECT
    store_id,
    store_name,
    city,
    state,
    sold_year,
    promo_id,
    promo_name,
    channel_email,
    discount_active,
    total_net_profit,
    total_sales,
    total_quantity,
    avg_discount_amount,
    distinct_orders,
    promo_duration_days,
    avg_days_to_ship,
    promo_rank
FROM (
    SELECT
        s_store_id AS store_id,
        s_store_name AS store_name,
        s_city AS city,
        s_state AS state,
        sold_year,
        p_promo_id AS promo_id,
        p_promo_name AS promo_name,
        p_channel_email AS channel_email,
        p_discount_active AS discount_active,
        total_net_profit,
        total_sales,
        total_quantity,
        avg_discount_amount,
        distinct_orders,
        promo_duration_days,
        avg_days_to_ship,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS promo_rank
    FROM promo_store_agg
) ranked
WHERE promo_rank <= 5
ORDER BY total_net_profit DESC
LIMIT 100
