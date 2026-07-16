SELECT
    s.s_store_id,
    s.s_store_name,
    dr_return.d_date AS return_date,
    dr_closed.d_date AS store_closed_date,
    r.r_reason_desc,
    COUNT(sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(sr.sr_store_credit) AS total_store_credit,
    s.s_floor_space,
    COUNT(DISTINCT wp_creation.wp_web_page_id) AS web_pages_created_on_return_date,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS web_pages_accessed_on_closed_date,
    COALESCE(SUM(wp_creation.wp_image_count), 0) AS total_images_created,
    COALESCE(SUM(wp_access.wp_image_count), 0) AS total_images_accessed,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_by_store
FROM store_returns sr
JOIN date_dim dr_return
    ON sr.sr_returned_date_sk = dr_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim dr_closed
    ON s.s_closed_date_sk = dr_closed.d_date_sk
LEFT JOIN web_page wp_creation
    ON wp_creation.wp_creation_date_sk = dr_return.d_date_sk
LEFT JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = dr_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    dr_return.d_date,
    dr_closed.d_date,
    r.r_reason_desc,
    s.s_floor_space
ORDER BY total_net_loss DESC
LIMIT 100
