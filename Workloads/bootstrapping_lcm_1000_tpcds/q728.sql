WITH agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS state,
        d_return.d_year AS return_year,
        d_return.d_quarter_name AS return_quarter,
        d_return.d_month_seq AS return_month,
        wp.wp_type AS page_type,
        d_wp_creation.d_year AS page_creation_year,
        d_wp_access.d_year AS page_access_year,
        d_store_closed.d_year AS store_closed_year,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        (SUM(wr.wr_return_amt) - SUM(wr.wr_net_loss)) AS gross_margin_estimate,
        COUNT(DISTINCT c_refunded.c_customer_id) AS distinct_refunded_customers,
        COUNT(DISTINCT c_returning.c_customer_id) AS distinct_returning_customers,
        COUNT(DISTINCT c_page_owner.c_customer_id) AS distinct_page_owner_customers
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c_page_owner
        ON wp.wp_customer_sk = c_page_owner.c_customer_sk
    CROSS JOIN date_dim d_store_closed
    JOIN store s
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cust_first_shipto
        ON c_refunded.c_first_shipto_date_sk = d_cust_first_shipto.d_date_sk
    JOIN date_dim d_cust_first_sales
        ON c_refunded.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
    JOIN date_dim d_cust_last_review
        ON c_refunded.c_last_review_date = d_cust_last_review.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_return.d_year,
        d_return.d_quarter_name,
        d_return.d_month_seq,
        wp.wp_type,
        d_wp_creation.d_year,
        d_wp_access.d_year,
        d_store_closed.d_year
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT
    store_id,
    store_name,
    state,
    return_year,
    return_quarter,
    return_month,
    page_type,
    page_creation_year,
    page_access_year,
    store_closed_year,
    num_returns,
    total_return_amt,
    total_net_loss,
    avg_return_quantity,
    gross_margin_estimate,
    distinct_refunded_customers,
    distinct_returning_customers,
    distinct_page_owner_customers,
    RANK() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS net_loss_rank_by_year
FROM agg
ORDER BY
    return_year,
    net_loss_rank_by_year
