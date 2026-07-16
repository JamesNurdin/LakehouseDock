SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    s.s_store_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    MIN(s.s_floor_space) AS min_floor_space,
    MAX(s.s_floor_space) AS max_floor_space,
    d_cp_end.d_current_month AS page_end_month,
    d_cp_start.d_current_month AS page_start_month,
    d_cust_shipto.d_current_month AS cust_first_shipto_month,
    d_cust_sales.d_current_month AS cust_first_sales_month,
    d_cust_last_review.d_current_month AS cust_last_review_month
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cust_shipto
    ON c_refunded.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
JOIN date_dim d_cust_sales
    ON c_refunded.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN date_dim d_cust_last_review
    ON c_refunded.c_last_review_date = d_cust_last_review.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND d_ret.d_year = 2021
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    s.s_store_name,
    d_cp_end.d_current_month,
    d_cp_start.d_current_month,
    d_cust_shipto.d_current_month,
    d_cust_sales.d_current_month,
    d_cust_last_review.d_current_month
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
