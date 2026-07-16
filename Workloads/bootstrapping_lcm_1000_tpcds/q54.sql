SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    cp.cp_catalog_page_number,
    cp.cp_type,
    return_date.d_year,
    return_date.d_month_seq,
    refunded_addr.ca_city AS refunded_city,
    returning_addr.ca_city AS returning_city,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    DATE_DIFF('day', page_start_date.d_date, return_date.d_date) AS days_from_page_start_to_return,
    DATE_DIFF('day', return_date.d_date, page_end_date.d_date) AS days_from_return_to_page_end,
    DATE_DIFF('day', page_start_date.d_date, page_end_date.d_date) + 1 AS page_duration_days,
    SUM(cr.cr_return_amount) / (DATE_DIFF('day', page_start_date.d_date, page_end_date.d_date) + 1) AS avg_return_amount_per_page_day
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim return_date
    ON cr.cr_returned_date_sk = return_date.d_date_sk
JOIN date_dim page_start_date
    ON cp.cp_start_date_sk = page_start_date.d_date_sk
JOIN date_dim page_end_date
    ON cp.cp_end_date_sk = page_end_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = return_date.d_date_sk
JOIN customer_address refunded_addr
    ON cr.cr_refunded_addr_sk = refunded_addr.ca_address_sk
JOIN customer_address returning_addr
    ON cr.cr_returning_addr_sk = returning_addr.ca_address_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    cp.cp_catalog_page_number,
    cp.cp_type,
    return_date.d_year,
    return_date.d_month_seq,
    return_date.d_date,
    refunded_addr.ca_city,
    returning_addr.ca_city,
    page_start_date.d_date,
    page_end_date.d_date
ORDER BY total_return_amount DESC
LIMIT 100
