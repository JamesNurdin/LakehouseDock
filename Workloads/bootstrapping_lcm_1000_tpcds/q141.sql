SELECT
    s.s_store_name,
    s.s_city,
    cd.d_year,
    cd.d_month_seq,
    COUNT(DISTINCT c_ref.c_customer_sk) AS distinct_catalog_refunded_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_catalog_returning_customers,
    COUNT(DISTINCT w_ref.c_customer_sk) AS distinct_web_refunded_customers,
    COUNT(DISTINCT w_ret.c_customer_sk) AS distinct_web_returning_customers,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(wr.wr_return_amt) AS avg_web_return_amount,
    MIN(c_ref.c_email_address) AS sample_catalog_refunded_email,
    MIN(w_ref.c_email_address) AS sample_web_refunded_email
FROM catalog_returns cr
JOIN date_dim cd ON cr.cr_returned_date_sk = cd.d_date_sk
JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = cd.d_date_sk
JOIN customer w_ref ON wr.wr_refunded_customer_sk = w_ref.c_customer_sk
JOIN customer w_ret ON wr.wr_returning_customer_sk = w_ret.c_customer_sk
JOIN store s ON s.s_closed_date_sk = cd.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    cd.d_year,
    cd.d_month_seq
ORDER BY (total_catalog_net_loss + total_web_net_loss) DESC
LIMIT 100
