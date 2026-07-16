SELECT
    d.d_year,
    d.d_month_seq,
    s.s_country,
    s.s_state,
    c_refunded.c_birth_year AS cr_refunded_birth_year,
    c_returning.c_birth_year AS cr_returning_birth_year,
    c_wr_refunded.c_birth_year AS wr_refunded_birth_year,
    c_wr_returning.c_birth_year AS wr_returning_birth_year,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_quantity,
    AVG(wr.wr_return_quantity) AS avg_web_return_quantity
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_country,
    s.s_state,
    c_refunded.c_birth_year,
    c_returning.c_birth_year,
    c_wr_refunded.c_birth_year,
    c_wr_returning.c_birth_year
ORDER BY d.d_year DESC, s.s_country
LIMIT 100
