WITH returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_refunded_customer_sk AS refunded_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_refunded_customer_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    (d_sales.d_year * 100 + d_sales.d_month_seq) AS year_month_key,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COALESCE(SUM(r.total_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(r.total_return_net_loss), 0) AS total_return_net_loss,
    SUM(ss.ss_ext_sales_price) - COALESCE(SUM(r.total_return_amount), 0) - COALESCE(SUM(r.total_return_net_loss), 0) AS net_sales_after_returns,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0
        THEN ROUND(100.0 * COALESCE(SUM(r.total_return_amount), 0) / SUM(ss.ss_ext_sales_price), 2)
        ELSE NULL
    END AS return_rate_percent,
    MIN(d_sales.d_date) AS first_sales_date,
    MAX(d_sales.d_date) AS last_sales_date,
    MIN(d_closed.d_date) AS store_closed_date,
    DATE_DIFF('day', MAX(d_sales.d_date), MIN(d_closed.d_date)) AS days_from_last_sale_to_store_close,
    AVG(DATE_DIFF('day', d_cust_first.d_date, d_sales.d_date)) AS avg_days_customer_first_to_sale,
    MIN(d_cust_first.d_date) AS earliest_customer_first_sales_date,
    MIN(d_cust_shipto.d_date) AS earliest_customer_first_shipto_date,
    MIN(d_cust_review.d_date) AS earliest_customer_last_review_date
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN returns_agg r
    ON r.returned_date_sk = d_sales.d_date_sk
    AND r.refunded_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_cust_first ON c.c_first_sales_date_sk = d_cust_first.d_date_sk
LEFT JOIN date_dim d_cust_shipto ON c.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
LEFT JOIN date_dim d_cust_review ON c.c_last_review_date = d_cust_review.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sales.d_year,
    d_sales.d_month_seq
HAVING SUM(ss.ss_quantity) > 0
ORDER BY net_sales_after_returns DESC
LIMIT 100
