SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    c.c_preferred_cust_flag,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_sales_after_returns,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MIN(d_sales.d_date) AS first_sale_date,
    MAX(d_sales.d_date) AS last_sale_date,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(cr.cr_net_loss) / SUM(ss.ss_ext_sales_price)
        ELSE NULL
    END AS return_loss_ratio
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_first_shipto
    ON c.c_first_shipto_date_sk = d_first_shipto.d_date_sk
LEFT JOIN date_dim d_first_sales
    ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
LEFT JOIN date_dim d_last_review
    ON c.c_last_review_date = d_last_review.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    c.c_preferred_cust_flag
ORDER BY net_sales_after_returns DESC
LIMIT 100
