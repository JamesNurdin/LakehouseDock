SELECT
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq,
    d_return.d_holiday AS return_holiday,
    c_refunded.c_customer_id AS refunded_customer_id,
    c_refunded.c_email_address AS refunded_email,
    c_returning.c_customer_id AS returning_customer_id,
    d_ship.d_year AS ship_year,
    d_sales.d_year AS sales_year,
    d_review.d_year AS review_year,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS num_returns
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_ship
    ON c_refunded.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c_refunded.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c_refunded.c_last_review_date = d_review.d_date_sk
GROUP BY
    i.i_category,
    i.i_brand,
    s.s_state,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_holiday,
    c_refunded.c_customer_id,
    c_refunded.c_email_address,
    c_returning.c_customer_id,
    d_ship.d_year,
    d_sales.d_year,
    d_review.d_year
ORDER BY total_return_amount DESC
LIMIT 100
