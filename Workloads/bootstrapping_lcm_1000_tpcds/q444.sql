WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date AS sold_date,
        t.t_hour,
        t.t_meal_time,
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2021
      AND t.t_meal_time IN ('Lunch', 'Dinner')
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        t.t_hour,
        t.t_meal_time,
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        p.p_cost,
        d_start.d_date,
        d_end.d_date
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.d_year,
    a.d_month_seq,
    a.sold_date,
    a.t_hour,
    a.t_meal_time,
    a.p_promo_id,
    a.p_promo_name,
    a.p_discount_active,
    a.p_cost,
    a.order_cnt,
    a.total_quantity,
    a.total_sales_price,
    a.total_discount_amount,
    a.total_net_profit,
    a.avg_sales_price,
    a.min_sales_price,
    a.max_sales_price,
    a.promo_start_date,
    a.promo_end_date,
    CASE WHEN a.p_cost > 0 THEN a.total_net_profit / a.p_cost ELSE NULL END AS promo_roi,
    RANK() OVER (PARTITION BY a.p_promo_id ORDER BY a.total_net_profit DESC) AS store_profit_rank,
    SUM(a.total_net_profit) OVER (
        PARTITION BY a.p_promo_id
        ORDER BY a.sold_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_promo_profit
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 200
