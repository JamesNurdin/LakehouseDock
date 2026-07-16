SELECT
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    i.i_category AS item_category,
    s.s_state AS store_state,
    wp.wp_type AS page_type,
    d_creation.d_month_seq AS page_creation_month,
    d_access.d_month_seq AS page_access_month,
    CASE WHEN i.i_color = 'Red' THEN 'Red Items' ELSE 'Other Colors' END AS color_group,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(i.i_wholesale_cost * wr.wr_return_quantity) AS total_wholesale_cost,
    AVG(i.i_current_price - i.i_wholesale_cost) AS avg_margin_per_item
FROM web_returns wr
JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    i.i_category,
    s.s_state,
    wp.wp_type,
    d_creation.d_month_seq,
    d_access.d_month_seq,
    CASE WHEN i.i_color = 'Red' THEN 'Red Items' ELSE 'Other Colors' END
ORDER BY total_return_amount DESC
LIMIT 100
