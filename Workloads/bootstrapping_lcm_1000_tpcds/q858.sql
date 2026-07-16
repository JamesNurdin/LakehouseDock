SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_date AS page_creation_date,
    d_wp_access.d_date AS page_access_date,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    d_return.d_date AS return_date,
    wr.wr_net_loss,
    wr.wr_reason_sk
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_return.d_year = 2023
  AND s.s_state = 'CA'
ORDER BY d_return.d_date DESC
LIMIT 100
