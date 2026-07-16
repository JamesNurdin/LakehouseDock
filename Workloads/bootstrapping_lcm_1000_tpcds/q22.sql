SELECT
    s.s_store_name,
    s.s_city AS store_city,
    ws.web_name,
    ws.web_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_tv,
    CASE
        WHEN d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status,
    d_web_close.d_year AS web_close_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ship.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_tv,
    CASE
        WHEN d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'Active'
        ELSE 'Inactive'
    END,
    d_web_close.d_year
ORDER BY total_net_paid DESC
LIMIT 100
