SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_id,
    p.p_promo_name,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cust_returning.c_birth_month) AS avg_returning_customer_birth_month,
    MIN(d_first_ship.d_date) AS first_ship_date,
    MIN(d_first_sales.d_date) AS first_sales_date,
    MIN(d_last_review.d_date) AS last_review_date,
    MIN(d_promo_end.d_date) AS promo_end_date,
    COUNT(DISTINCT cust_refunded.c_customer_id) AS distinct_refunded_customers
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_first_ship
    ON cust_returning.c_first_shipto_date_sk = d_first_ship.d_date_sk
JOIN date_dim d_first_sales
    ON cust_returning.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
    ON cust_returning.c_last_review_date = d_last_review.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
  AND p.p_cost > 1000
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    p.p_promo_id,
    p.p_promo_name,
    d_return.d_year,
    d_return.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
