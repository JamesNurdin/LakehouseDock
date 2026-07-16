WITH aggregated_sales AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        p.p_promo_name AS promo_name,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        t.t_hour AS sale_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d_sold.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        d_sold.d_date,
        d_ship.d_date,
        d_promo_start.d_date,
        d_promo_end.d_date,
        t.t_hour
)
SELECT
    store_id,
    store_name,
    store_city,
    promo_name,
    sold_date,
    ship_date,
    promo_start_date,
    promo_end_date,
    sale_hour,
    total_quantity,
    total_net_profit,
    avg_discount_amt,
    promo_rank
FROM (
    SELECT
        store_id,
        store_name,
        store_city,
        promo_name,
        sold_date,
        ship_date,
        promo_start_date,
        promo_end_date,
        sale_hour,
        total_quantity,
        total_net_profit,
        avg_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_net_profit DESC) AS promo_rank
    FROM aggregated_sales
) ranked
WHERE promo_rank <= 5
ORDER BY store_id, promo_rank
