WITH returns_with_dates AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        d_ret.d_date AS return_date
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
),
store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_closed_date_sk,
        d_scl.d_year AS store_closed_year,
        d_scl.d_date AS store_closed_date
    FROM store s
    JOIN date_dim d_scl ON s.s_closed_date_sk = d_scl.d_date_sk
),
web_page_dates AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        wp.wp_customer_sk,
        d_cr.d_year AS wp_creation_year,
        d_ac.d_year AS wp_access_year
    FROM web_page wp
    JOIN date_dim d_cr ON wp.wp_creation_date_sk = d_cr.d_date_sk
    JOIN date_dim d_ac ON wp.wp_access_date_sk = d_ac.d_date_sk
)
SELECT
    rwd.cr_order_number,
    rwd.cr_return_amount,
    rwd.cr_return_quantity,
    rwd.cr_net_loss,
    rwd.return_year,
    rwd.return_month,
    rwd.return_date,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    c_ret.c_customer_id AS returning_customer_id,
    s.s_store_name,
    s.s_state,
    s.store_closed_year,
    wp.wp_url,
    wp.wp_type,
    wp.wp_creation_year,
    wp.wp_access_year,
    COALESCE(d_first_shipto.d_year, -1) AS first_shipto_year,
    COALESCE(d_first_sales.d_year, -1) AS first_sales_year,
    COALESCE(d_last_review.d_year, -1) AS last_review_year,
    SUM(rwd.cr_return_amount) OVER (PARTITION BY s.s_store_sk) AS store_total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY rwd.return_date DESC) AS rn_customer_returns
FROM returns_with_dates rwd
JOIN customer c ON rwd.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer c_ret ON rwd.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN store_dates s ON s.s_closed_date_sk = rwd.cr_returned_date_sk
JOIN web_page_dates wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_first_shipto ON c.c_first_shipto_date_sk = d_first_shipto.d_date_sk
LEFT JOIN date_dim d_first_sales ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
LEFT JOIN date_dim d_last_review ON c.c_last_review_date = d_last_review.d_date_sk
WHERE rwd.cr_return_amount > 0
  AND s.s_state = 'CA'
  AND wp.wp_type = 'product'
GROUP BY
    rwd.cr_order_number,
    rwd.cr_return_amount,
    rwd.cr_return_quantity,
    rwd.cr_net_loss,
    rwd.return_year,
    rwd.return_month,
    rwd.return_date,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    c_ret.c_customer_id,
    s.s_store_name,
    s.s_state,
    s.store_closed_year,
    wp.wp_url,
    wp.wp_type,
    wp.wp_creation_year,
    wp.wp_access_year,
    d_first_shipto.d_year,
    d_first_sales.d_year,
    d_last_review.d_year,
    c.c_customer_sk,
    s.s_store_sk
HAVING SUM(rwd.cr_return_amount) > 1000
ORDER BY rwd.return_date DESC
LIMIT 100
