SELECT
    s.s_store_id,
    s.s_store_name,
    d_cr.d_year,
    d_cr.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_net_loss) AS store_total_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(sr.sr_return_amt) AS store_return_amount,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    CASE
        WHEN (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) <> 0
        THEN SUM(cr.cr_return_amount) / (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss))
        ELSE NULL
    END AS return_to_loss_ratio,
    COUNT(DISTINCT c_ref.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT c_sr.c_customer_sk) AS distinct_store_return_customers
FROM catalog_returns cr
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN date_dim d_cust_sales
    ON c_ref.c_first_sales_date_sk = d_cust_sales.d_date_sk
WHERE d_cr.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_cr.d_year,
    d_cr.d_month_seq
ORDER BY
    s.s_store_id,
    d_cr.d_month_seq
LIMIT 100
