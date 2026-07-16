SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    i.i_brand,
    i.i_category,
    i.i_product_name,
    i.i_color,
    i.i_size,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_date AS page_start_date,
    d_end.d_date AS page_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_fee) AS avg_return_fee,
    COUNT(*) AS return_count
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cp.cp_type IS NOT NULL
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_page_number,
    i.i_brand,
    i.i_category,
    i.i_product_name,
    i.i_color,
    i.i_size,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_start.d_date,
    d_end.d_date,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
