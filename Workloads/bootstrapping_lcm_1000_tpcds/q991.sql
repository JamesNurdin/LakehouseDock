SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    d_return.d_fy_year,
    d_return.d_quarter_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fees,
    SUM(COALESCE(wp.wp_image_count, 0)) AS total_image_count,
    SUM(COALESCE(wp.wp_link_count, 0)) AS total_link_count,
    MAX(d_closed.d_date) AS store_closed_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
    SUM(CASE WHEN d_access.d_dow IN (6, 7) THEN sr.sr_return_amt ELSE 0 END) AS weekend_return_amount
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE i.i_category IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    d_return.d_fy_year,
    d_return.d_quarter_name
ORDER BY total_return_amount DESC
LIMIT 100
