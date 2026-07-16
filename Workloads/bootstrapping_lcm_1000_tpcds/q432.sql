SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date AS first_sales_date,
    d_ship.d_date AS first_shipto_date,
    d_review.d_date AS last_review_date,
    p.p_promo_name,
    d_end.d_date AS promo_end_date,
    s.s_store_name,
    w.web_name,
    d_sales.d_date AS web_open_date,
    d_end.d_date AS web_close_date,
    p.p_cost * p.p_response_target AS promo_potential_value,
    date_diff('day', d_sales.d_date, d_end.d_date) AS days_between_sales_and_promo_end,
    date_diff('day', d_end.d_date, d_review.d_date) AS days_between_promo_end_and_review,
    date_diff('day', d_ship.d_date, d_review.d_date) AS days_between_ship_and_review,
    date_diff('day', d_sales.d_date, d_ship.d_date) AS days_between_sales_and_ship,
    ROW_NUMBER() OVER (ORDER BY date_diff('day', d_sales.d_date, d_end.d_date) DESC) AS rank
FROM
    customer c
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ship ON c.c_first_shipto_date_sk = d_ship.d_date_sk
    JOIN date_dim d_review ON c.c_last_review_date = d_review.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_sales.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d_sales.d_date_sk
                     AND w.web_close_date_sk = d_end.d_date_sk
ORDER BY
    rank
