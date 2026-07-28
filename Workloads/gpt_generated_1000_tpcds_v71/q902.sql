WITH agg AS (
    SELECT
        wp.wp_type AS wp_type,
        wp.wp_customer_sk AS wp_customer_sk,
        DATE_TRUNC('month', wp.wp_rec_start_date) AS start_month,
        COUNT(*) AS page_views,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        MIN(wr.wr_return_amt) AS min_return_amount,
        MAX(wr.wr_return_amt) AS max_return_amount
    FROM web_page wp
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_rec_start_date >= DATE '2000-01-01'
        AND wp.wp_rec_end_date <= DATE '2001-12-31'
        AND wp.wp_type IN ('home', 'search', 'product')
        AND wp.wp_char_count BETWEEN 500 AND 2000
        AND wr.wr_return_quantity > 0
        AND wr.wr_reversed_charge < 100.00
        AND wr.wr_refunded_cash >= 50.00
    GROUP BY
        wp.wp_type,
        wp.wp_customer_sk,
        DATE_TRUNC('month', wp.wp_rec_start_date)
)
SELECT
    wp_type,
    wp_customer_sk,
    start_month,
    page_views,
    total_return_amount,
    avg_return_amount,
    total_refunded_cash,
    min_return_amount,
    max_return_amount,
    SUM(total_return_amount) OVER (PARTITION BY wp_type ORDER BY start_month) AS cum_return_by_type,
    RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
