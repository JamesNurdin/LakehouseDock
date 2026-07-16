SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(ws.ws_ext_discount_amt) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS discount_rate,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date,
    COUNT(*) AS row_cnt
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE t.t_am_pm = 'PM'
  AND p.p_discount_active = 'Y'
  AND d_sold.d_year = 2022
GROUP BY ROLLUP (d_sold.d_year, d_sold.d_month_seq, s.s_state, p.p_promo_name)
HAVING COUNT(*) > 10
ORDER BY total_sales DESC
LIMIT 100
