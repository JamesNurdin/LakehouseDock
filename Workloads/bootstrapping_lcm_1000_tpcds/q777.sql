WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_month_seq AS ship_month,
        d_ship.d_quarter_name AS ship_quarter,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(p.p_cost) AS promo_cost,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_promo_cost
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_month_seq,
        d_ship.d_quarter_name,
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date,
        d_end.d_date
)
SELECT
    store_id,
    store_name,
    sold_year,
    sold_month,
    ship_month,
    ship_quarter,
    promo_id,
    promo_name,
    promo_start_date,
    promo_end_date,
    total_sales,
    total_net_paid,
    total_profit,
    total_quantity,
    order_cnt,
    avg_discount,
    promo_cost,
    active_promo_cost,
    CASE
        WHEN active_promo_cost = 0 THEN NULL
        ELSE (total_profit - active_promo_cost) / active_promo_cost
    END AS roi,
    RANK() OVER (PARTITION BY sold_year, sold_month ORDER BY total_profit DESC) AS profit_rank_month
FROM sales_agg
ORDER BY sold_year, sold_month, profit_rank_month
