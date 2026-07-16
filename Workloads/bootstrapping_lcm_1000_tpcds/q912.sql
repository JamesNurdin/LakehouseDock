SELECT
    d_sold.d_year AS sale_year,
    d_ship.d_moy AS ship_month,
    p.p_promo_name,
    s.s_state,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS billing_birth_quarter,
    CASE
        WHEN c_ship.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c_ship.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c_ship.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS shipping_birth_quarter,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_list_price) AS avg_list_price,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_net_paid > 0
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_ship.d_moy,
    p.p_promo_name,
    s.s_state,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    CASE
        WHEN c_ship.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c_ship.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c_ship.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date)
ORDER BY total_net_paid DESC
LIMIT 100
