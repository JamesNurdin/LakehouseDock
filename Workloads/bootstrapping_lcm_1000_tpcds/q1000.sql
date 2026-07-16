SELECT
    s.s_city,
    w.w_state,
    DATE_FORMAT(dd_sold.d_date, '%Y-%m') AS sold_month,
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END AS promo_channel,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_quantity * cs.cs_sales_price) AS total_sales_amount,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_discount_amt) AS net_sales_excl_discount
FROM catalog_sales cs
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN store s
    ON s.s_closed_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_promo_start
    ON p.p_start_date_sk = dd_promo_start.d_date_sk
JOIN date_dim dd_promo_end
    ON p.p_end_date_sk = dd_promo_end.d_date_sk
WHERE dd_sold.d_year = 2022
  AND dd_ship.d_year = 2022
  AND dd_promo_start.d_date <= dd_sold.d_date
  AND dd_promo_end.d_date >= dd_sold.d_date
GROUP BY
    s.s_city,
    w.w_state,
    DATE_FORMAT(dd_sold.d_date, '%Y-%m'),
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_profit DESC
LIMIT 100
