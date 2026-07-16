WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        w.web_site_id,
        w.web_name,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month,
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(p.p_cost) AS total_promo_cost,
        date_diff('day', MIN(d_promo_start.d_date), MAX(d_promo_end.d_date)) AS promo_duration_days,
        MIN(d_web_open.d_date) AS web_open_date,
        MIN(d_web_close.d_date) AS web_close_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN date_dim d_web_open
        ON w.web_open_date_sk = d_web_open.d_date_sk
    LEFT JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        w.web_site_id,
        w.web_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state
)
SELECT
    p_promo_id,
    p_promo_name,
    web_site_id,
    web_name,
    sold_year,
    sold_month,
    ship_year,
    ship_month,
    s_store_id,
    s_city,
    s_state,
    total_net_paid,
    total_net_profit,
    total_discount,
    avg_sales_price,
    order_count,
    total_promo_cost,
    promo_duration_days,
    web_open_date,
    web_close_date,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_profit DESC) AS profit_rank_within_promo
FROM sales_agg
ORDER BY overall_profit_rank
LIMIT 100
