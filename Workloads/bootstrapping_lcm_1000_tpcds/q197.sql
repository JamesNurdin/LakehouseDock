SELECT
    store_id,
    store_name,
    city,
    promo_id,
    promo_name,
    sold_year,
    sold_month,
    cust_first_ship_year,
    promo_start_year,
    total_net_profit,
    total_quantity,
    avg_discount,
    distinct_customers,
    weekend_quantity,
    RANK() OVER (PARTITION BY store_id ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_city AS city,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_cust_first_ship.d_year AS cust_first_ship_year,
        d_promo_start.d_year AS promo_start_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_quantity ELSE 0 END) AS weekend_quantity
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cust_first_ship
        ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        p.p_promo_id,
        p.p_promo_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_cust_first_ship.d_year,
        d_promo_start.d_year
) t
ORDER BY total_net_profit DESC
LIMIT 100
