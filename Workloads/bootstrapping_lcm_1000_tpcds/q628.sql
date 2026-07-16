SELECT
    s.s_store_name,
    s.s_state,
    wp.wp_type,
    DATE_TRUNC('month', d_return.d_date) AS return_month,
    CASE WHEN cr.cr_return_quantity > 5 THEN 'large' ELSE 'small' END AS return_size_category,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cust_refunded.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT cust_returning.c_customer_sk) AS distinct_returning_customers,
    AVG(YEAR(current_date) - cust_refunded.c_birth_year) AS avg_refunded_customer_age,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_quantity ELSE 0 END) AS high_quantity_returned,
    MIN(d_return.d_date) AS earliest_return_date,
    MAX(d_return.d_date) AS latest_return_date,
    MIN(d_store_closed.d_date) AS store_closed_date,
    MIN(d_wp_creation.d_date) AS wp_creation_date,
    MIN(d_wp_access.d_date) AS wp_access_date,
    MIN(d_cust_first_sales.d_date) AS cust_first_sales_date,
    MIN(d_cust_first_ship.d_date) AS cust_first_ship_date,
    MIN(d_cust_last_review.d_date) AS cust_last_review_date
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON 1 = 1
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer cust_web
    ON wp.wp_customer_sk = cust_web.c_customer_sk
JOIN date_dim d_cust_first_sales
    ON cust_refunded.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_first_ship
    ON cust_refunded.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_last_review
    ON cust_refunded.c_last_review_date = d_cust_last_review.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_state,
    wp.wp_type,
    DATE_TRUNC('month', d_return.d_date),
    CASE WHEN cr.cr_return_quantity > 5 THEN 'large' ELSE 'small' END
