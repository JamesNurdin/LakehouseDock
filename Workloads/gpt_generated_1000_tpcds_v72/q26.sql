WITH wr_details AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_web_page_sk,
        c_refunded.c_customer_id AS refunded_customer_id,
        c_returning.c_customer_id AS returning_customer_id,
        d_ret.d_year AS return_year,
        t_ret.t_shift AS return_shift,
        wp.wp_url,
        wp.wp_type,
        d_creation.d_year AS page_creation_year,
        d_access.d_year AS page_access_year,
        c_page.c_customer_id AS page_owner_id,
        CASE
            WHEN wr.wr_return_amt > 100 THEN 'High'
            WHEN wr.wr_return_amt > 0 THEN 'Low'
            ELSE 'Zero'
        END AS return_amount_category
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN customer c_page
        ON wp.wp_customer_sk = c_page.c_customer_sk
    JOIN date_dim d_ship
        ON c_refunded.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_sales
        ON c_refunded.c_first_sales_date_sk = d_sales.d_date_sk
)
SELECT
    return_year,
    return_shift,
    wp_type,
    COUNT(DISTINCT wr_order_number) AS num_returns,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT refunded_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT returning_customer_id) AS distinct_returning_customers,
    SUM(CASE WHEN return_amount_category = 'High' THEN wr_return_amt ELSE 0 END) AS high_amount_total
FROM wr_details
GROUP BY
    return_year,
    return_shift,
    wp_type
ORDER BY
    total_return_amount DESC,
    num_returns DESC
LIMIT 100
