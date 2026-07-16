WITH aggregated_returns AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        ca_ref.ca_city AS refunded_city,
        ca_ret.ca_city AS returning_city,
        s.s_store_name AS s_store_name,
        s.s_city AS store_city,
        wp.wp_type AS wp_type,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        SUM(wp.wp_image_count) AS total_image_count,
        MIN(d_ret.d_date) AS first_return_date,
        MAX(d_ret.d_date) AS last_return_date
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_create
        ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_wp_create.d_date_sk
    WHERE d_ret.d_year >= 2020
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        ca_ref.ca_city,
        ca_ret.ca_city,
        s.s_store_name,
        s.s_city,
        wp.wp_type
)
SELECT
    return_year,
    return_month,
    refunded_city,
    returning_city,
    s_store_name,
    store_city,
    wp_type,
    total_returns,
    total_return_amount,
    total_fee,
    avg_return_qty,
    total_image_count,
    first_return_date,
    last_return_date,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_return_amount DESC) AS store_rank
FROM aggregated_returns
ORDER BY total_return_amount DESC
LIMIT 100
