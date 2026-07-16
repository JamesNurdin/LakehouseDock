SELECT
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_type,
    s.s_store_name,
    s.s_state,
    d_ret.d_date AS return_date,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    wp.wp_url,
    wp.wp_type,
    d_access.d_date AS wp_access_date,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_amount - cr.cr_refunded_cash) AS net_refund
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year = 2023
  AND s.s_state = 'CA'
  AND cp.cp_type = 'Special'
GROUP BY
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_type,
    s.s_store_name,
    s.s_state,
    d_ret.d_date,
    d_start.d_date,
    d_end.d_date,
    wp.wp_url,
    wp.wp_type,
    d_access.d_date
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
