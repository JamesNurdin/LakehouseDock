WITH store_closure AS (
    SELECT
        dd.d_date AS closed_date,
        COUNT(DISTINCT s.s_store_id) AS stores_closed_cnt
    FROM store s
    JOIN date_dim dd ON s.s_closed_date_sk = dd.d_date_sk
    GROUP BY dd.d_date
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    dd_start.d_date AS promo_start_date,
    dd_end.d_date AS promo_end_date,
    w.w_warehouse_name,
    w.w_city,
    dd_ship.d_date AS ship_date,
    AVG(date_diff('day', dd_sold.d_date, dd_ship.d_date)) AS avg_days_to_ship,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_coupon_amt) AS total_coupons,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COALESCE(sc.stores_closed_cnt, 0) AS stores_closed_on_ship_date
FROM web_sales ws
INNER JOIN date_dim dd_sold ON ws.ws_sold_date_sk = dd_sold.d_date_sk
INNER JOIN date_dim dd_ship ON ws.ws_ship_date_sk = dd_ship.d_date_sk
INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN date_dim dd_start ON p.p_start_date_sk = dd_start.d_date_sk
INNER JOIN date_dim dd_end ON p.p_end_date_sk = dd_end.d_date_sk
LEFT JOIN store_closure sc ON sc.closed_date = dd_ship.d_date
WHERE dd_sold.d_year = 2023
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    dd_start.d_date,
    dd_end.d_date,
    w.w_warehouse_name,
    w.w_city,
    dd_ship.d_date,
    sc.stores_closed_cnt
ORDER BY total_sales DESC
LIMIT 100
