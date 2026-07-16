WITH aggregated_sales AS (
    SELECT
        d_sold.d_year AS sale_year,
        d_sold.d_quarter_name AS sale_quarter,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_ship.d_weekend AS ship_weekend,
        d_store_closed.d_year AS store_closed_year,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        AVG(ws.ws_quantity) AS avg_quantity,
        AVG(hd_bill.hd_vehicle_count) AS avg_vehicle_count,
        AVG(hd_ship.hd_dep_count) AS avg_ship_dependent_count
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    CROSS JOIN store s
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_ship.d_weekend = 'Y'
      AND d_sold.d_year >= 2000
    GROUP BY
        d_sold.d_year,
        d_sold.d_quarter_name,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_ship.d_weekend,
        d_store_closed.d_year,
        d_promo_start.d_date,
        d_promo_end.d_date
)
SELECT
    sale_year,
    sale_quarter,
    s_store_id,
    s_state,
    p_promo_id,
    p_promo_name,
    total_net_profit,
    total_discount,
    distinct_orders,
    avg_quantity,
    avg_vehicle_count,
    avg_ship_dependent_count,
    CASE WHEN ship_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS ship_day_type,
    store_closed_year,
    promo_start_date,
    promo_end_date,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank_by_store
FROM aggregated_sales
ORDER BY total_net_profit DESC
LIMIT 100
