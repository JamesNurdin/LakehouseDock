SELECT
    promo_id,
    promo_name,
    promo_start_date,
    promo_end_date,
    sold_year,
    ship_month_seq,
    total_sales_amount,
    total_net_profit,
    avg_discount_amount,
    total_inventory_on_start_date,
    stores_closed_during_promo,
    ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
FROM (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        d_sold.d_year AS sold_year,
        d_ship.d_month_seq AS ship_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_on_start_date,
        COUNT(DISTINCT s.s_store_id) AS stores_closed_during_promo
    FROM
        web_sales ws
        JOIN date_dim d_sold
            ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
            ON ws.ws_ship_date_sk = d_ship.d_date_sk
        JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN date_dim d_start
            ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end
            ON p.p_end_date_sk = d_end.d_date_sk
        LEFT JOIN inventory i
            ON i.inv_date_sk = d_start.d_date_sk
        LEFT JOIN store s
            ON s.s_closed_date_sk = d_end.d_date_sk
    WHERE
        d_start.d_date BETWEEN DATE '2020-01-01' AND DATE '2023-12-31'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date,
        d_end.d_date,
        d_sold.d_year,
        d_ship.d_month_seq
) sub
ORDER BY total_sales_amount DESC
LIMIT 100
