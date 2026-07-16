SELECT
    d_ret.d_year AS return_year,
    (d_ret.d_month_seq % 2) AS month_parity,
    CASE WHEN p.p_discount_active = 'Y' THEN 'DiscountActive' ELSE 'NoDiscount' END AS discount_status,
    s.s_state AS store_state,
    s.s_city AS store_city,
    c.c_birth_country AS birth_country,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_quantity) AS total_quantity,
    COUNT(*) AS total_returns
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_cust_ship ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_store ON wr.wr_returned_date_sk = d_store.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_promo ON wr.wr_returned_date_sk = d_promo.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_promo.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_ret.d_year,
    (d_ret.d_month_seq % 2),
    CASE WHEN p.p_discount_active = 'Y' THEN 'DiscountActive' ELSE 'NoDiscount' END,
    s.s_state,
    s.s_city,
    c.c_birth_country
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
