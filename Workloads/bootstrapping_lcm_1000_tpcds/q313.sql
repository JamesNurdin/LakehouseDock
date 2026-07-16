SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_state AS store_state,
    s.s_market_desc AS market_description,
    wp.wp_type AS web_page_type,
    d_cust_ship.d_year AS first_ship_year,
    d_cust_sales.d_year AS first_sales_year,
    d_cust_review.d_year AS last_review_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_reversed_charge) AS total_reversed_charge,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT rcust.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT rturn_cust.c_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    MIN(d_wp_create.d_date) AS earliest_page_creation,
    MAX(d_wp_access.d_date) AS latest_page_access,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN 1 ELSE 0 END) AS returns_with_tax,
    AVG(wp.wp_image_count) AS avg_image_count,
    date_diff(
        'day',
        MIN(d_cust_ship.d_date),
        MAX(d_cust_review.d_date)
    ) AS days_between_first_ship_and_last_review
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer rcust
    ON cr.cr_refunded_customer_sk = rcust.c_customer_sk
JOIN customer rturn_cust
    ON cr.cr_returning_customer_sk = rturn_cust.c_customer_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = rcust.c_customer_sk
LEFT JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
LEFT JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN date_dim d_cust_ship
    ON rcust.c_first_shipto_date_sk = d_cust_ship.d_date_sk
LEFT JOIN date_dim d_cust_sales
    ON rcust.c_first_sales_date_sk = d_cust_sales.d_date_sk
LEFT JOIN date_dim d_cust_review
    ON rcust.c_last_review_date = d_cust_review.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    d_cust_ship.d_year,
    d_cust_sales.d_year,
    d_cust_review.d_year
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
