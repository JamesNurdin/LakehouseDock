SELECT
    cp.cp_type,
    dd_return.d_year AS return_year,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT rc.c_customer_sk) AS num_refunded_customers,
    COUNT(DISTINCT rcn.c_customer_sk) AS num_returning_customers,
    MIN(cp.cp_catalog_page_number) AS min_page_number,
    MAX(cp.cp_catalog_page_number) AS max_page_number
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dd_return
    ON cr.cr_returned_date_sk = dd_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_return.d_date_sk
JOIN date_dim dd_catalog_end
    ON cp.cp_end_date_sk = dd_catalog_end.d_date_sk
JOIN customer rc
    ON cr.cr_refunded_customer_sk = rc.c_customer_sk
JOIN customer rcn
    ON cr.cr_returning_customer_sk = rcn.c_customer_sk
JOIN date_dim dd_customer_ship
    ON rc.c_first_shipto_date_sk = dd_customer_ship.d_date_sk
WHERE cp.cp_type = 'RETURN'
GROUP BY cp.cp_type, dd_return.d_year, s.s_state
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
