SELECT
    p.p_promo_name,
    wsite.web_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(sc.closed_store_count, 0) AS closed_store_count,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin
FROM
    web_sales ws
    INNER JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    INNER JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    INNER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN date_dim d_site_open ON wsite.web_open_date_sk = d_site_open.d_date_sk
    INNER JOIN date_dim d_site_close ON wsite.web_close_date_sk = d_site_close.d_date_sk
    LEFT JOIN (
        SELECT
            d_sc.d_year,
            d_sc.d_month_seq,
            COUNT(DISTINCT s.s_store_sk) AS closed_store_count
        FROM
            store s
            INNER JOIN date_dim d_sc ON s.s_closed_date_sk = d_sc.d_date_sk
        GROUP BY
            d_sc.d_year,
            d_sc.d_month_seq
    ) sc ON sc.d_year = d_sold.d_year AND sc.d_month_seq = d_sold.d_month_seq
WHERE
    p.p_discount_active = 'Y'
    AND d_sold.d_year >= 2020
GROUP BY
    p.p_promo_name,
    wsite.web_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    sc.closed_store_count
ORDER BY
    total_profit DESC
LIMIT 100
