SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT cust_ref.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT cust_ret.c_customer_sk) AS distinct_returning_customers,
    AVG(DATE_DIFF('day', d_first_sales.d_date, d.d_date)) AS avg_days_since_first_sales,
    AVG(DATE_DIFF('day', d_first_ship.d_date, d.d_date)) AS avg_days_since_first_ship,
    AVG(DATE_DIFF('day', d_last_review.d_date, d.d_date)) AS avg_days_since_last_review,
    CASE
        WHEN SUM(cr.cr_return_amount) > 0 THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount)
        ELSE NULL
    END AS net_loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN date_dim d_first_ship
    ON cust_ref.c_first_shipto_date_sk = d_first_ship.d_date_sk
JOIN date_dim d_first_sales
    ON cust_ref.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
    ON cust_ref.c_last_review_date = d_last_review.d_date_sk
WHERE d.d_year BETWEEN 2010 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 50
