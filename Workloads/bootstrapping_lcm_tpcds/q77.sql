SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    p.p_promo_name,
    p.p_channel_email,
    s.s_store_name,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(p.p_cost) AS avg_promo_cost
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
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    p.p_promo_name,
    p.p_channel_email,
    s.s_store_name,
    s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
