SELECT
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date   AS promo_end_date,
    ws.ws_order_number,
    ws.ws_sales_price,
    ws.ws_net_profit,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    ws_site.web_name AS website_name,
    ws_site.web_city AS website_city,
    d_open.d_date AS site_open_date,
    d_close.d_date AS site_close_date,
    (
        SELECT COUNT(*)
        FROM store s
        JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
        WHERE d_store.d_date <= d_end.d_date
    ) AS stores_closed_by_promo_end,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
JOIN web_sales ws    ON ws.ws_promo_sk    = p.p_promo_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_open ON ws_site.web_open_date_sk  = d_open.d_date_sk
JOIN date_dim d_close ON ws_site.web_close_date_sk = d_close.d_date_sk
ORDER BY ws.ws_net_profit DESC
LIMIT 100
