SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    r.r_reason_desc,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    COUNT(DISTINCT cu_refunded.c_customer_id) AS distinct_customers,
    SUM(CASE WHEN cu_refunded.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_returns,
    SUM(CASE WHEN s.s_market_desc = 'Online' THEN cr.cr_return_amount ELSE 0 END) AS online_store_return_amount,
    MAX(d_ship.d_date) AS last_ship_date,
    MAX(d_sale.d_date) AS last_sales_date
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer cu_refunded
    ON cr.cr_refunded_customer_sk = cu_refunded.c_customer_sk
JOIN customer cu_returning
    ON cr.cr_returning_customer_sk = cu_returning.c_customer_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_ship
    ON cu_refunded.c_first_shipto_date_sk = d_ship.d_date_sk
LEFT JOIN date_dim d_sale
    ON cu_refunded.c_first_sales_date_sk = d_sale.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2002
    AND s.s_market_desc IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    r.r_reason_desc,
    d_return.d_year,
    d_return.d_month_seq
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
