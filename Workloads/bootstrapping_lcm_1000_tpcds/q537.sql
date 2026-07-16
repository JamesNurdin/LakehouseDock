SELECT
    d_sold.d_year AS sold_year,
    CASE WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_store_name,
    p.p_promo_name,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_customers,
    SUM(CASE WHEN p.p_channel_email = 'Y' THEN cs.cs_ext_discount_amt ELSE 0 END) AS email_discount_total,
    CASE
        WHEN SUM(cs.cs_net_paid) > 500000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_paid) > 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS revenue_category
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
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
JOIN date_dim d_c_first_shipto
    ON c_ship.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales
    ON c_bill.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN date_dim d_c_last_review
    ON c_bill.c_last_review_date = d_c_last_review.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_sold.d_year,
    CASE WHEN d_sold.d_month_seq BETWEEN 1 AND 6 THEN 'H1' ELSE 'H2' END,
    s.s_store_name,
    p.p_promo_name
HAVING
    SUM(cs.cs_net_paid) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
